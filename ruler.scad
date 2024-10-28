$empty = true;
include <jig.scad>;

difference() {
  plate(r=0){
    wire_mount_rounded(wires=sockets*2, high=true,clasp=true);

    translate([0,big_spacing*sockets /*+ wire_mount_length*/,0])
      wire_mount_rounded(wires=sockets*2, high=true,clasp=true);
  }

  let(y=.5, z=.5)
    for (i=[1:sockets-1]) {
      translate([-(wire_mount_width +wire_width * sockets), i * big_spacing + wire_mount_length/2 - y/2, -z])
        cube([2*i*wire_width + wire_mount_width, y, z]);
    }
}
