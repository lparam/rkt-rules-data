package main

import (
	"flag"
	"fmt"
	"net"
	"os"
	"sort"
	"strings"
	"time"

	"github.com/maxmind/mmdbwriter"
	"github.com/maxmind/mmdbwriter/inserter"
	"github.com/maxmind/mmdbwriter/mmdbtype"
	"github.com/oschwald/geoip2-golang"
	"github.com/oschwald/maxminddb-golang"
)

func main() {
	var inputPath, outputPath string
	flag.StringVar(&inputPath, "input", "raw/Country.mmdb", "Path to input Country.mmdb")
	flag.StringVar(&outputPath, "output", "publish/geoip.rdb", "Path to output geoip.rdb")
	flag.Parse()

	startTime := time.Now()
	fmt.Printf("➕ Loading MaxMind database: %s\n", inputPath)

	binary, err := os.ReadFile(inputPath)
	if err != nil {
		fmt.Fprintf(os.Stderr, "❌ Failed to read input file %s: %v\n", inputPath, err)
		os.Exit(1)
	}

	database, err := maxminddb.FromBytes(binary)
	if err != nil {
		fmt.Fprintf(os.Stderr, "❌ Failed to parse MaxMind database: %v\n", err)
		os.Exit(1)
	}

	metadata := database.Metadata
	networks := database.Networks(maxminddb.SkipAliasedNetworks)
	countryMap := make(map[string][]*net.IPNet)
	var country geoip2.Enterprise
	var ipNet *net.IPNet
	totalNetworks := 0

	for networks.Next() {
		ipNet, err = networks.Network(&country)
		if err != nil {
			fmt.Fprintf(os.Stderr, "❌ Error scanning network: %v\n", err)
			os.Exit(1)
		}
		code := strings.ToLower(country.RegisteredCountry.IsoCode)
		if code == "" {
			code = strings.ToLower(country.Country.IsoCode)
		}
		if code != "" {
			countryMap[code] = append(countryMap[code], ipNet)
			totalNetworks++
		}
	}

	if err = networks.Err(); err != nil {
		fmt.Fprintf(os.Stderr, "❌ Error iterating networks: %v\n", err)
		os.Exit(1)
	}

	fmt.Printf("📦 Scanned %d CIDRs across %d ISO country codes\n", totalNetworks, len(countryMap))

	allCodes := make([]string, 0, len(countryMap))
	for code := range countryMap {
		allCodes = append(allCodes, code)
	}
	sort.Strings(allCodes)

	writer, err := mmdbwriter.New(mmdbwriter.Options{
		DatabaseType:            "sing-geoip",
		Languages:               allCodes,
		IPVersion:               int(metadata.IPVersion),
		RecordSize:              int(metadata.RecordSize),
		Inserter:                inserter.ReplaceWith,
		DisableIPv4Aliasing:     true,
		IncludeReservedNetworks: true,
	})
	if err != nil {
		fmt.Fprintf(os.Stderr, "❌ Failed to create mmdbwriter: %v\n", err)
		os.Exit(1)
	}

	fmt.Println("🔁 Building Radix Tree and coalescing adjacent CIDR blocks...")
	for _, code := range allCodes {
		for _, item := range countryMap[code] {
			if err = writer.Insert(item, mmdbtype.String(code)); err != nil {
				fmt.Fprintf(os.Stderr, "❌ Error inserting %s (%s): %v\n", item, code, err)
				os.Exit(1)
			}
		}
	}

	outDir := outputPath[:strings.LastIndex(outputPath, "/")]
	if outDir != "" {
		_ = os.MkdirAll(outDir, 0755)
	}

	outFile, err := os.Create(outputPath)
	if err != nil {
		fmt.Fprintf(os.Stderr, "❌ Failed to create output file: %v\n", err)
		os.Exit(1)
	}
	defer outFile.Close()

	n, err := writer.WriteTo(outFile)
	if err != nil {
		fmt.Fprintf(os.Stderr, "❌ Failed to write database: %v\n", err)
		os.Exit(1)
	}

	fmt.Printf("🎉 Successfully compiled pure GeoIP database to %s (%d bytes, %.2f MB) in %v\n",
		outputPath, n, float64(n)/(1024*1024), time.Since(startTime))
}
