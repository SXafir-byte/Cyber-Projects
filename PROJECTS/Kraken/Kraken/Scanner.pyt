import sys
import socket

def scan_ports(target, start_port, end_port):
    print(f"Starting scan on {target} from port {start_port} to {end_port}...\n")
    open_ports = []
    for port in range(start_port, end_port + 1):
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(0.5)
        result = sock.connect_ex((target, port))
        if result == 0:
            print(f"Port {port}: OPEN")
            open_ports.append(port)
        sock.close()
    if not open_ports:
        print("No open ports found.")
    else:
        print(f"\nScan complete. Open ports: {open_ports}")

def main():
    if len(sys.argv) != 4:
        print("Usage: python3 port_scanner.py <target> <start_port> <end_port>")
        sys.exit(1)

    target = sys.argv[1]
    try:
        start_port = int(sys.argv[2])
        end_port = int(sys.argv[3])
    except ValueError:
        print("Ports must be integers.")
        sys.exit(1)

    if start_port < 1 or end_port > 65535 or start_port > end_port:
        print("Invalid port range. Ports must be between 1 and 65535, and start <= end.")
        sys.exit(1)

    scan_ports(target, start_port, end_port)

if __name__ == "__main__":
    main()
