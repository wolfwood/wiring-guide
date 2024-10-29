$empty = true;
include <jig.scad>;

difference() {
  plate(r=0){
    wire_mount_rounded(wires=sockets*2, high=true,clasp=true);

    // For the distance between the mounts to be equal to big_spacing, we should add wire_mount_length.
    // However, one end of the ribbon will already be cut, so by adding nothing and feeding to the end of
    // the mount, the last cut should be big_spacing from the end. In practice, the last bit of ribbon comes
    // up a bit short, so we split the difference and add half the mount length.
    translate([0,big_spacing*sockets + wire_mount_length/2,0])
      wire_mount_rounded(wires=sockets*2, high=true,clasp=true);
  }

  let(y=.5, z=.5)
    for (i=[1:sockets-1]) {
      translate([-(wire_mount_width +wire_width * sockets), i * big_spacing + wire_mount_length/2 - y/2, -z])
        cube([2*i*wire_width + wire_mount_width, y, z]);
    }
}
