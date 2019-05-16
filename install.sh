parted <<EOF
mklabel msdos
      
      
        
mkpart primary ext2 1 400M
      
      
        
mkpart primary ext4 2 400M 100%
      
      
        
set 1 boot on
      
      
        
set 2 LVM on
      
      
        
EOF
