import socket

def listen_on_port(ip, port):
    server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server_socket.bind((ip, port))
    server_socket.listen(5)

    print(f"Listening on {ip}:{port}... Press Ctrl+C to stop.")

    try:
        while True:
            client_socket, addr = server_socket.accept()
            print(f"Connection from {addr}")
            client_socket.sendall(b"Hello, you connected!\n")
            client_socket.close()
    except KeyboardInterrupt:
        print("\nStopping listener.")
    finally:
        server_socket.close()

def main():
    ip = input("Enter IP address to listen on (use 0.0.0.0 for all interfaces): ")
    port = int(input("Enter port to listen on: "))
    
    if port < 1 or port > 65535:
        print("Invalid port number.")
        return
    
    listen_on_port(ip, port)

if __name__ == "__main__":
    main()