if status is-interactive
    # Commands to run in interactive sessions can go here
    source (/usr/local/bin/starship init fish --print-full-init | psub)
    export EDITOR=vim
	if test -z $TMUX
        exec tmux
    end
end

source ~/.local/base/bin/activate.fish

function kerninit
	set cwd (pwd)

	if test (count $argv) -ne 0
		set dir $argv[1]
	else
		set dir $cwd 
	end
	
	cd $dir
	# 查找以.gz结尾的文件
    set gz_file (find . -name "*.gz" -print -quit)

    # 如果找到.gz文件，解压并重命名
    if test -n "$gz_file"
        gunzip "$gz_file"
        set raw_file (basename "$gz_file" .gz)
        mv -i "$raw_file" rootfs.cpio
    else
        # 查找以.img或.cpio结尾的文件并判断是否为gzip文件
        set img_file (find . -name "*.img" -o -name "*.cpio" -print -quit)
        if test -n "$img_file"
            if file "$img_file" | grep -q "gzip compressed"
                mv -i "$img_file" temp.gz
                gunzip temp.gz
                mv -i temp rootfs.cpio
            else
                mv -i "$img_file" rootfs.cpio
            end
        else
            echo "No .gz, .img or .cpio file found."
            cd $cwd
			exit 1
        end
    end

    # 新建rootfs文件夹并解包rootfs.cpio
    mkdir -p rootfs
    cd rootfs
    cpio -id < ../rootfs.cpio
	cd ..	
	if not test -e "vmlinux"
		~/ctf/workspace/extract-vmlinux.sh ./bzImage > vmlinux
	end

	vmlinux-to-elf vmlinux vmlinux.elf

	cd $cwd
end
