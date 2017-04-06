/*
   SwiftyGPIO

   Copyright (c) 2016 Umberto Raimondi
   Licensed under the MIT license, as follows:

   Permission is hereby granted, free of charge, to any person obtaining a copy
   of this software and associated documentation files (the "Software"), to deal
   in the Software without restriction, including without limitation the rights
   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
   copies of the Software, and to permit persons to whom the Software is
   furnished to do so, subject to the following conditions:

   The above copyright notice and this permission notice shall be included in all
   copies or substantial portions of the Software.

   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
   SOFTWARE.)
*/
#if os(Linux)
    import Glibc
#else
    import Darwin.C
#endif

extension SwiftyGPIO {

    public static func UARTs(for board: SupportedBoard) -> [UARTInterface]? {
        switch board {
        case .RaspberryPiRev1:
            fallthrough
        case .RaspberryPiRev2:
            fallthrough
        case .RaspberryPiPlusZero:
            fallthrough
        case .RaspberryPi2:
            fallthrough
        case .RaspberryPi3:
            return [UARTRPI[0]!]
        default:
            return nil
        }
    }
}

// MARK: - UART Presets
extension SwiftyGPIO {
    // RaspberryPis SPIs
    static let UARTRPI: [Int:UARTInterface] = [
        0: SysFSUART("AMA0")!
    ]
}

// MARK: UART
public protocol UARTInterface {
	func configureInterface(speed: UARTSpeed, bitsPerChar: CharSize, stopBits: StopBits, parity: ParityType)
    func readString() -> String
    func readLine() -> String
    func readData() -> [CChar]
    func writeString(_ value: String)
    func writeData(_ values: [CChar])
}


public enum ParityType {
	case None
	case Even
	case Odd

	public func configure(_ cfg: inout termios){
		switch self {
			case .None:
				cfg.c_cflag &= ~UInt32(PARENB | PARODD)  
			case .Even:
				cfg.c_cflag &= ~UInt32(PARENB | PARODD)  
				cfg.c_cflag |= UInt32(PARENB)
			case .Odd:
				cfg.c_cflag |= UInt32(PARENB | PARODD)
		}
	}
}

public enum CharSize {
	case Eight
	case Seven
	case Six

	public func configure(_ cfg: inout termios){
		cfg.c_cflag = (cfg.c_cflag & ~UInt32(CSIZE))
		switch self {
			case .Eight:
				cfg.c_cflag |= UInt32(CS8)
			case .Seven:
				cfg.c_cflag |= UInt32(CS7)
			case .Six:
				cfg.c_cflag |= UInt32(CS6)
		}
	}
}

public enum StopBits {
	case One
	case Two

	public func configure(_ cfg: inout termios){
		switch self {
			case .One:
				cfg.c_cflag &= ~UInt32(CSTOPB)
			case .Two:
				cfg.c_cflag |= UInt32(CSTOPB)
		}
	}
}

public enum UARTSpeed {
	case S9600
	case S19200
	case S38400
	case S57600
	case S115200
	
	public func configure(_ cfg: inout termios) {
		switch self {
			case .S9600:
				cfsetispeed(&cfg, speed_t(B9600))
				cfsetospeed(&cfg, speed_t(B9600))
			case .S19200:
				cfsetispeed(&cfg, speed_t(B19200))
				cfsetospeed(&cfg, speed_t(B19200))
			case .S38400:
				cfsetispeed(&cfg, speed_t(B38400))
				cfsetospeed(&cfg, speed_t(B38400))
			case .S57600:
				cfsetispeed(&cfg, speed_t(B57600))
				cfsetospeed(&cfg, speed_t(B57600))
			case .S115200:
				cfsetispeed(&cfg, speed_t(B115200))
				cfsetospeed(&cfg, speed_t(B115200))
		}
	}
}


/// UART via SysFS
public final class SysFSUART: UARTInterface {
	var device: String
	var tty: termios
	var fd: Int32

	public init?(_ uartId: String){
		device = "/dev/tty"+uartId
		tty = termios()

		fd = open(device, O_RDWR | O_NOCTTY | O_SYNC)
		guard fd>0 else {
			perror("Couldn't open UART device")
			abort()
		}

		let ret = tcgetattr(fd, &tty)

		guard ret == 0 else {
			perror("Couldn't get terminal attributes")
			abort()
		}
	}

	public func configureInterface(speed: UARTSpeed, bitsPerChar: CharSize, stopBits: StopBits, parity: ParityType){
		speed.configure(&tty)

		bitsPerChar.configure(&tty)
		tty.c_iflag &= ~UInt32(IGNBRK)      // disable break processing
		tty.c_lflag =  0    				// no signaling chars, no echo,
			                         		// no canonical processing -> read bytes as they come without waiting for LF
        tty.c_oflag = 0                     // no remapping, no delays

        withUnsafeMutableBytes(of: &tty.c_cc){$0[Int(VMIN)] = UInt8(1); return}
		withUnsafeMutableBytes(of: &tty.c_cc){$0[Int(VTIME)] = UInt8(5); return} // 5 10th of second read timeout
		tty.c_iflag &= ~UInt32(IXON | IXOFF | IXANY) // Every kind of software flow control off
		tty.c_cflag &= ~UInt32(CRTSCTS)  //No hw flow control
		tty.c_cflag |= UInt32(CLOCAL | CREAD)        // Ignore modem controls, enable read
		parity.configure(&tty)
		stopBits.configure(&tty)

		applyConfiguration()
	}

	public func readLine() -> String {
        var buf = [CChar](repeating:0, count: 4097) //4096 chars at max in canonical mode
        var ptr = UnsafeMutablePointer<CChar>(&buf)
        var pos = 0

        repeat {
            let n = read(fd, ptr, MemoryLayout<CChar>.stride)
            if n<0 {
                perror("Error while reading from UART")
                abort()
            }
            ptr += 1
            pos += 1
        } while buf[pos-1] != CChar(UInt8(ascii: "\n"))
		
        buf[pos] = 0
		return String(cString: &buf)
	}

	public func readString() -> String {
		var buf = readData()
		buf.append(0) //Add terminator to convert cString correctly
		return String(cString: &buf)
	}

	public func readData() -> [CChar] {
		var buf = [CChar](repeating:0, count: 4096) //4096 chars at max in canonical mode
		
		let n = read(fd, &buf, buf.count * MemoryLayout<CChar>.stride)
		if n<0 {
			perror("Error while reading from UART")
			abort()
		}
		return Array(buf[0..<n])
	}

	public func writeString(_ value: String) {
		let chars = Array(value.utf8CString)

		writeData(chars)
	}

	public func writeData(_ value: [CChar]) {
		var value = value

		let _ = write(fd, &value, value.count)
		tcdrain(fd)
	}

	private func applyConfiguration(){
		if tcsetattr (fd, TCSANOW, &tty) != 0 {
			perror("Couldn't set terminal attributes")
			abort()
		}
	}

	deinit {
		close(fd)
	}

}






