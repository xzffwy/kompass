---
title: VirtualBox Linux Shrink 
date: 2016/3/15 9:07:14 
description:  VirtualBox Linux Shrink 
categories: 技术
tags: [Windows]
---

#### Start the Linux Virtual Machine ####
Start the Linux Virtual Machine and log in with administrative rights.

####  Clean any free disk space ####
The most effective way to clean free disk space on a Linux drive is to use the Linux **dd** utility which is a bit-stream duplicator. Open up a terminal window and type the following command:

    dd if=/dev/zero of=zerofillfile bs=1M
This command will zero-fill any free disk space on the virtual Linux drive.

- **if=** specifies the input file;
- **/dev/zero** indicates a bit-stream of zeros
- **of=** specifies the output file
- **zerofillfile** name of the file containing the bit-stream of zeros
- **bs=** indicates the block size
- **1M** indicates that the block size will be 1 megabyte

Once the dd has completed, you will see a message in your terminal window indicating that there is no space left on the device:

    dd: writing 'zerofillfile': No space left on device
You can now remove zerofillfile using the Linux rm utility:

    rm zerofillfile

#### Shutdown the Linux Virtual Machine ####
End your session and shutdown the Linux Virtual Machine.

#### Compact the Linux guest image ####
To compact the Linux guest image, use the VirtualBox VBoxManage utility. Assuming a Windows host, use the following command at the DOS prompt:

    VBoxManage modifyhd --compact "[drive]:\[path_to_image_file]\[name_of_image_file].vdi"

Ensure that you replace the items in square brackets with your parameters.

If your Windows host complains that **VBoxManage** cannot be found or is an invalid command, you may need to explicitly specify the path to the VirtualBox executables. So a complete example for compacting a Linux guest image at the DOS prompt is as follows:

    C:\> path C:\Program Files\Oracle\VirtualBox
    C:\> VBoxManage modifyhd --compact "C:\netreliant_VMs\linux_001.vdi"

Once the VirtualBox **VBoxManage** utility is running you will see progress indicators in 10% increments starting from 0% to 100%. And once the process is complete, you should have a smaller disk image file.