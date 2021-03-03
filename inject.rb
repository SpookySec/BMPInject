require "colorize"
require "tty-prompt"

class BMPImage
    attr_reader :file_name
    attr_reader :file_size

    def initialize(file_name)
        @file_name = file_name
        begin
            @file_size = File.size(@file_name)
        rescue
            puts "[-] File '#{self.file_name}' Doesn't Exist".colorize(:red)
            exit!
        end

        @key = "spooky_is_awesome"
    end

    def is_bmp?
        return true if File.extname(self.file_name) == ".bmp"
        return false
    end

    def injected?
        chunk = File.binread(self.file_name)
        found = chunk.include?(@key)
        return true if found
        return false
    end
    
    def inject(str)
        buf = String.new
        File.open(self.file_name, "rb") do |f|
            buf = f.read
        end
        
        buf += @key
        buf += str
        return File.binwrite(self.file_name, buf)
    end

    def read_injected
        return unless self.injected?

        chunk = File.binread(self.file_name)
        offset = chunk.index(@key)
        data = String.new

        open(self.file_name, "rb") do |f|
            f.seek(0)
            f.seek(offset + @key.length)
            data = f.read
        end

        return data unless data.nil?
    end
end

if ARGV.count < 1
    puts "Usage: #{__FILE__} <BMP File>".colorize(:white)
    exit!
end

begin
    pmt = TTY::Prompt.new
    bmp = BMPImage.new(ARGV[0])

    unless bmp.is_bmp?
        puts "[-] File Doesn't Look Like a BMP Image!".colorize(:red)
        exit!
    end

    puts "[~] File Is a BMP Image!".colorize(:white)

    if bmp.injected?
        puts "[!] File Already Has Data".colorize(:yellow)
        puts "[*] Data Extracted: #{bmp.read_injected}".colorize(:green) if pmt.yes?("[?] Would You Like To Read The Data Stored?")
    else
        puts "[*] File is Empty!".colorize(:green)
        if pmt.yes?("[?] Would You Like To Inject Data?")
            data = pmt.ask("info>> ")
            nbytes = bmp.inject(data)
            puts "[*] Injected #{nbytes - bmp.file_size} to #{bmp.file_name}!".colorize(:green)
        end
    end
rescue
    puts "[-] Exiting".colorize(:red)
    exit!
end