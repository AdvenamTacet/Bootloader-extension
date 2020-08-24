all:
	echo "RUN: make run | repair | update | show"

zero:
	dd if=/dev/zero of=minix.img conv=notrunc bs=1 count=446

run:
	qemu-system-x86_64 -enable-kvm -cpu host -drive format=raw,file=minix.img -net user,hostfwd=tcp::7777-:22 -net nic,model=virtio -m 2048M &

repair:
	dd if=minix.img.backup of=minix.img conv=notrunc bs=512 count=32

update: repair zero
	nasm -f bin boot.asm -o boot
	dd if=boot of=minix.img conv=notrunc bs=1 count=446
	dd if=minix.img.backup of=minix.img conv=notrunc bs=512 seek=1 count=1
	rm boot

show:
	xxd -pl -l 1048 minix.img

export:
	rm -rf export_dir
	mkdir export_dir
	cp boot.asm export_dir/.
	cp makefile export_dir/.
	cp auto-login export_dir/.
	tar -zcf export.tar.gz export_dir
	rm -rf export_dir

bin-view:
	dd if=minix.img of=tmp.bin bs=512 count=16
	binja tmp.bin
	rm tmp.bin
