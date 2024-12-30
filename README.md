## Pnet Hammer LoadTester  
![](https://github.com/Socxenophone/PnetBarricade/blob/main/splash.png) 

Pnet comes with advanced features for **real-time metrics**, concurrent requests, traffic simulation, **user-agent, ip rotation**, basic port scanning and fingerprinting, and **multi-protocol support**, including SSl/TLS , HTTPS, FTP, MQTT, etc. This tool simulates a modern Distributed Denial of Service (DDoS) scenario, for anyone looking to test their web infrastructure.  



*Work in progress : Expect breaking changes*
<!-- TOC start -->


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

- Support for FTP, MQT, WebSocket, HTTP/S, etc Multi-Protocol Support 
- Request Customization
- Rate Limiting
- Response Time Analysis
- IP Rotation (Proxies)
- Result Visualization 
- Stress Test Simulation
- User-Agent Rotation 
- Interactive Batch Mode
  
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
- [ ] Custom Traffic Profiles 
- [ ] Bot-net features 
- [ ] GUI 

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

> **Disclaimer**  
> This tool is intended for ethical and legal use only. The developer is not responsible for any misuse or unlawful activities conducted with this tool. Always ensure that your actions comply with the laws and regulations of your jurisdiction.

