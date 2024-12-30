## Pnet Hammer LoadTester  
![](https://github.com/Socxenophone/PnetBarricade/blob/main/splash.png) 

Pnet comes with advanced features for **real-time metrics**, concurrent requests, traffic simulation, **user-agent, ip rotation**, basic port scanning and fingerprinting, and **multi-protocol support**, including SSl/TLS , HTTPS, FTP, MQTT, etc. This tool simulates a modern Distributed Denial of Service (DDoS) scenario, for anyone looking to test their web infrastructure.  

*Work in progress : Expect breaking changes*
<!-- TOC start -->

- [Pnet Hammer LoadTester  ](#pnet-hammer-loadtester)
- [Features](#features)
- [Installation](#installation)
- [Usage](#usage)
- [FAQ](#faq)
   * [Real-Time Metrics](#real-time-metrics)
   * [Data Collection](#data-collection)
   * [Traffic Simulation Profiles](#traffic-simulation-profiles)
- [Contributing](#contributing)
- [Roadmap ](#roadmap)
- [License](#license)

<!-- TOC end -->

## Features

- **Request Customization**: Choose HTTP methods (GET, POST, PUT, DELETE), customize headers, and send data in request bodies.
- **Rate Limiting**: Control the number of requests sent per second to simulate real-world traffic.
- **Response Time Analysis**: Record and display average, minimum, and maximum response times.
- **IP Rotation (Proxies)**: Simulate requests from different IPs using proxy servers.
- **Result Visualization**: Provide visual metrics like a histogram of response times.
- **Timeouts and Retries**: Set request timeouts and implement retry logic for failed requests.
- **Support for HTTPS**: Ensure requests work with both HTTP and HTTPS.
- **Stress Test Simulation**: Simulate various scenarios like increasing traffic over time (ramp-up testing) and sustained high traffic (stress testing).
- **User-Agent Rotation**: Randomize `User-Agent` headers to mimic requests from various devices and browsers.
- **Interactive Mode**: Run tests interactively or in automated batch mode.
- **Multi-Protocol Support**: Expanded support for HTTP/HTTPS, WebSocket, FTP, and MQTT.

## Installation

1. **Compile the Program**: Ensure you have a Pascal compiler installed (e.g., Free Pascal).
2. **Compile the Source Code**:
   ```bash
   fpc hammer.pas
   ```

## Usage

Run with URL and bots specified:
   ```bash
   ./hammer --url=https://example.com --bots=100
   ```

Include a timeout for each request:
   ```bash
   ./hammer --url=https://example.com --bots=50 --timeout=5000
   ```
Print version information:
   ```bash
   ./hammer --version
   ```
For detailed usage see the  help message:
   ```bash
   ./hammer --help
   ```

## FAQ
### Real-Time Metrics

During execution, the program displays live stats:
- Requests Sent
- Successful Requests
- Last Response Time

### Data Collection

Results are saved to:
- **`load_test.log`**: Logs errors and responses.
- **`load_test_results.json`**: Contains response codes and latencies in JSON format.

### Traffic Simulation Profiles

The program supports predefined traffic patterns:
- **Spike**: Simulates a spike in traffic.
- **Wave**: Simulates waves of traffic.
- **Sustained**: Simulates sustained high traffic.



## Contributing

Contributions are welcome! Please open an issue or submit a pull request if you have any improvements or bug fixes.

## Roadmap 
- [x] Basic Implementation 
- [x] Request Customising + Concurrent requests 
- [x] IP/User-Agent Rotation 
- [x] Port scanning & fingerprinting 
- [x] Multi Protocol Support 
- [ ] GUI 

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
```

