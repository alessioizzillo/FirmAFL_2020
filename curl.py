#!/usr/bin/env python3
import os, sys

firm_dir = "FirmAE/scratch/"
ip = sys.argv[1]

def main():
    dir_list = os.listdir(firm_dir)

    cmd = []
    for name in dir_list:
        syscall_log_path = firm_dir+name+"/debug/syscall.log"
        fd = open(syscall_log_path, "a")
        fd.write("\n\n************************************\n")
        fd.write("************************************\n")
        fd.write("* SENT GET REQUEST TO %s! *\n" % ip)
        fd.write("************************************\n")
        fd.write("************************************\n\n\n")
        fd.close()

    os.system("curl %s 2>&1 > /dev/null" % ip)

main()