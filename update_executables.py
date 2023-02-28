#!/usr/bin/env python3
#This script is used after finished the user_mode/ and qemu_mode/ compilation. In this way all the executables are saved in the folders of the firmware in the database
try:
	import sys
	import os
	import pdb
	from pathlib import Path

except ImportError as e:
	# Error and Exception Handling
    print("Some modules could not be imported from stdlib('sys' , 'os', 'pdb', 'pathlib', 're', 'subprocess' , 'signal')")

firm_dir = "FirmAE/scratch/"

def main():
	#Bash lines to update the new executable of user_mode and qemu_mode

	dir_list = os.listdir(firm_dir)

	cmd = []
	for name in dir_list:
		with open(firm_dir+"/"+name+"/architecture", "r") as file:
			firm_architecture = str(file.readline().rstrip())

		if ("mipseb" in firm_architecture):
			cmd.append("sudo cp AFL/afl-fuzz "+ firm_dir+name+"/")
			
			# FirmAFL
			cmd.append("sudo cp qemu_mode/DECAF_qemu_2.10/mips-softmmu/qemu-system-mips "+ firm_dir+name+"/")
			cmd.append("sudo cp user_mode/mips-linux-user/qemu-mips "+ firm_dir+name+"/afl-qemu-trace")

			# EQUAFL
			cmd.append("sudo mv qemu_mode_equafl/DECAF_qemu_2.10/mips-softmmu/qemu-system-mips qemu_mode_equafl/DECAF_qemu_2.10/mips-softmmu/qemu-system-mips_equafl")
			cmd.append("sudo cp qemu_mode_equafl/DECAF_qemu_2.10/mips-softmmu/qemu-system-mips_equafl "+ firm_dir+name+"/")
			cmd.append("sudo mv qemu_mode_equafl/DECAF_qemu_2.10/mips-softmmu/qemu-system-mips_equafl qemu_mode_equafl/DECAF_qemu_2.10/mips-softmmu/qemu-system-mips")
			
		elif ("mipsel" in firm_architecture):
			cmd.append("sudo cp AFL/afl-fuzz "+ firm_dir+name+"/")

			# FirmAFL			
			cmd.append("sudo cp qemu_mode/DECAF_qemu_2.10/mipsel-softmmu/qemu-system-mipsel "+ firm_dir+name+"/")
			cmd.append("sudo cp user_mode/mipsel-linux-user/qemu-mipsel "+ firm_dir+name+"/afl-qemu-trace")

			# EQUAFL
			cmd.append("sudo mv qemu_mode_equafl/DECAF_qemu_2.10/mipsel-softmmu/qemu-system-mipsel qemu_mode_equafl/DECAF_qemu_2.10/mipsel-softmmu/qemu-system-mipsel_equafl")
			cmd.append("sudo cp qemu_mode_equafl/DECAF_qemu_2.10/mipsel-softmmu/qemu-system-mipsel_equafl "+ firm_dir+name+"/")
			cmd.append("sudo mv qemu_mode_equafl/DECAF_qemu_2.10/mipsel-softmmu/qemu-system-mipsel_equafl qemu_mode_equafl/DECAF_qemu_2.10/mipsel-softmmu/qemu-system-mipsel")

		else:
			cmd.append("sudo cp AFL/afl-fuzz "+ firm_dir+name+"/")

			# FirmAFL
			cmd.append("sudo cp qemu_mode/DECAF_qemu_2.10/arm-softmmu/qemu-system-arm "+ firm_dir+name+"/")
			cmd.append("sudo cp user_mode/arm-linux-user/qemu-arm "+ firm_dir+name+"/afl-qemu-trace")

			# EQUAFL
			cmd.append("sudo mv qemu_mode_equafl/DECAF_qemu_2.10/arm-softmmu/qemu-system-arm qemu_mode_equafl/DECAF_qemu_2.10/arm-softmmu/qemu-system-arm_equafl")
			cmd.append("sudo cp qemu_mode_equafl/DECAF_qemu_2.10/arm-softmmu/qemu-system-arm_equafl "+ firm_dir+name+"/")
			cmd.append("sudo mv qemu_mode_equafl/DECAF_qemu_2.10/arm-softmmu/qemu-system-arm_equafl qemu_mode_equafl/DECAF_qemu_2.10/arm-softmmu/qemu-system-arm")

	#sudo cp qemu_mode/DECAF_qemu_2.10/mips-softmmu/qemu-system-mips FirmAE/scratch/id/
	#sudo cp qemu_mode/DECAF_qemu_2.10/mipsel-softmmu/qemu-system-mipsel FirmAE/scratch/id/
	#sudo cp qemu_mode/DECAF_qemu_2.10/arm-softmmu/qemu-system-arm FirmAE/scratch/id/
	#sudo cp user_mode/mipsel-linux-user/qemu-mipsel FirmAE/scratch/id/afl-qemu-trace
	#sudo cp user_mode/mips-linux-user/qemu-mips FirmAE/scratch/id/afl-qemu-trace
	#sudo cp user_mode/mips-linux-user/qemu-mips FirmAE/scratch/id/afl-qemu-trace
	#sudo cp user_mode/arm-linux-user/qemu-arm FirmAE/scratch/id/afl-qemu-trace

	
	for i in range(0, len(cmd)):
		os.system(cmd[i])

if __name__ == "__main__":
    main()