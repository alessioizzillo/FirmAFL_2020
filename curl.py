#!/usr/bin/env python3
import os

firm_dir = "FirmAE/scratch/"

def main():
    dir_list = os.listdir(firm_dir)

    cmd = []
    for name in dir_list:
        syscall_log_path = firm_dir+name+"/debug/syscall.log"
        fd = open(syscall_log_path, "a")
        fd.write("\n\n************************************\n")
        fd.write("************************************\n")
        fd.write("* SENT GET REQUEST TO 192.168.0.1! *\n")
        fd.write("************************************\n")
        fd.write("************************************\n\n\n")
        fd.close()

    os.system("curl 192.168.0.1 2>&1 > /dev/null")

main()