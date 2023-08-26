
hs_width=1.8;
hs_length=13.2;

hs_height=6.85;
hs_offset=2.2;

wire_width=1.2;
wire_length=3;

module hotswap_mount(){
  let(x=2.1,y=3,z=7.2) {
    translate([-x/2,hs_width/2,0]) cube([x,y,z]);
    translate([-x/2,-y -hs_width/2,0]) cube([x,y,z]);
  }
}

module wire_mount(wires=1, low,mid,high){
  floor = (is_undef(low) && is_undef(mid) && is_undef(high)) ||
    !is_undef(low)  ? hs_height/2 - hs_offset/2 - wire_width/2 :
    !is_undef(mid)  ? hs_height/2 - wire_width/2 :
    !is_undef(high) ? hs_height/2 + hs_offset/2 - wire_width/2 :
    assert("wut?");

  let(x=1.8,y=wire_length,z=7.2, wire_width=wires*wire_width) {
    translate([wire_width/2,-y/2,0]) cube([x,y,z]);
    translate([-x -wire_width/2,-y/2,0]) cube([x,y,z]);

    let(x=wire_width+x) translate([-x/2,-y/2,0]) cube([x,y,floor]);
  }
}

module wire_mount_rounded(wires=1,low,mid,high){
  floor = (is_undef(low) && is_undef(mid) && is_undef(high)) ||
    !is_undef(low)  ? hs_height/2 - hs_offset/2 - wire_width/2 :
    !is_undef(mid)  ? hs_height/2 - wire_width/2 :
    !is_undef(high) ? hs_height/2 + hs_offset/2 - wire_width/2 :
    assert("wut?");

  let(x=1.8,y=wire_length,z=7.2, wire_width=wires*wire_width) {
    translate([wire_width/2+x/2,0,0]) linear_extrude(z) hull() {
      translate([0,y/2-x/2,0]) circle($fn=60,d=x);
      translate([0,-(y/2-x/2),0]) circle($fn=60,d=x);

    }

    translate([-(wire_width/2+x/2),0,0]) linear_extrude(z) hull() {
      translate([0,wire_length/2-x/2,0]) circle($fn=60,d=x);
      translate([0,-(wire_length/2-x/2),0]) circle($fn=60,d=x);

    }

    let(x=wire_width+x) translate([-x/2,-y/2,0]) cube([x,y,floor]);
    //translate([wire_width/2+x/2,0,0]) cylinder($fn=30,d=x,h=z);
    //translate([-wire_width/2-x/2,0,0]) cylinder($fn=30,d=x,h=z);
  }
}

hotswap_mount();

let(gap=.2) {
  translate([-hs_length/2,-gap-hs_width/2-wire_length/2,0]) wire_mount_rounded();
  translate([hs_length/2,-gap-hs_width/2-wire_length/2,0]) wire_mount_rounded();

  translate([0,-wire_width/2 -hs_length/2-wire_length -gap-hs_width/2-wire_length/2,0]) wire_mount_rounded(2,mid=true);

  translate([0,wire_width/2-hs_length/2-wire_length -gap-hs_width/2,0])
    //linear_extrude(7.5) polygon([[0,0],[2,2],[-2,2]]);
    linear_extrude(7.2) polygon([[0,0],[3,3],[-3,3]]);
}

let(x=20,y=20,z=2) translate([-x/2,-y/2-5,-z]) cube([x,y,z]);
