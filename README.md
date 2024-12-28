## Pnet Hammer LoadTester  
![](https://github.com/Socxenophone/PnetBarricade/blob/main/splash.png) 

Pnet comes with advanced features for **real-time metrics**, traffic simulation, **user-agent rotation**, and **multi-protocol support**, including SSl/TLS , HTTPS, FTP, MQTT, etc. This tool simulates a modern Distributed Denial of Service (DDoS) scenario, for anyone looking to test their web infrastructure.  

*Work in progress : Expect breaking changes*

---

### Features  
1. **Real-Time Metrics**: See live stats during execution, including:  
   - Total requests sent  
   - Errors encountered  
   - Average latency  

2. **Data Collection**: Save results in JSON format for post-analysis, including response codes and latencies.  

3. **Traffic Simulation Profiles**: Choose from predefined traffic patterns:  
   - Spikes: Sudden bursts of requests.  
   - Waves: Gradual increases and decreases in traffic.  
   - Sustained: Constant high load.  

4. **Multi-Protocol Support**: Test beyond HTTP/HTTPS with added support for:  
   - WebSocket  
   - FTP  
   - MQTT  

5. **Concurrency**: Run high numbers of simultaneous requests for load testing.  

6. **Request Customization**: Modify headers, payloads, and methods (GET, POST, etc.).  

7. **SSL/TLS and HTTPS Support**: Securely test websites with full HTTPS support.  

8. **Rate Limiting**: Control the rate of requests per second for more realistic tests.  

9. **User-Agent Rotation**: Simulate diverse client devices with random user-agent strings.  

---

### Requirements  
- **Pascal Compiler**: Free Pascal recommended.  
- **Libraries**:  
  - Indy (TIdHTTP, TIdSSLIOHandlerSocketOpenSSL).  
  - JSON handling libraries.  

---

### Usage  

Compile:  
```bash
fpc LoadTester.pas -o loadtester
```  

Run:  
```bash
./loadtester [options]
```  
#### CLI Options  
- **`--url` or `-u`**: Target URL (required).  
  Example: `--url=https://example.com`  

- **`--bots` or `-b`**: Number of concurrent bots (default: 10).  
  Example: `--bots=100`  

- **`--timeout` or `-t`**: Request timeout in seconds (default: 5).  
  Example: `--timeout=10`  

- **`--rate-limit` or `-r`**: Limit requests per second (default: no limit).  
  Example: `--rate-limit=50`  

- **`--profile` or `-p`**: Select traffic profile (`spike`, `wave`, `sustained`).  
  Example: `--profile=wave`  

- **`--save` or `-s`**: Save results to a JSON file.  
  Example: `--save=results.json`  

- **`--protocol` or `-P`**: Specify protocol (`http`, `websocket`, `ftp`, `mqtt`).  
  Example: `--protocol=websocket`  

- **`--user-agent` or `-ua`**: Enable random user-agent rotation.  

- **`--help` or `-h`**: Display usage instructions.  

---

### Examples  
#### Real-Time Metrics with HTTPS:  
```bash
./loadtester --url=https://example.com --bots=50 --timeout=10 --rate-limit=20 --user-agent
```  

#### Spiked Traffic Pattern:  
```bash
./loadtester --url=https://example.com --bots=100 --profile=spike --save=spike_results.json
```  

#### Multi-Protocol Test (WebSocket):  
```bash
./loadtester --url=wss://example.com/socket --protocol=websocket --bots=30
```  

---

### Notes  
- **Real-Time Metrics**: Stats will be displayed live in the console during execution.  
- **JSON Output**: Includes response codes, latencies, and errors for detailed analysis.  
- **Responsible Use**: Always test websites you own or have explicit permission to test.  

---

### Contributing  
Contributions are welcome. If you have ideas for new features or bug fixes, submit an issue or pull request.  

---

### License  
This tool is open-source under the [MIT License](LICENSE).
