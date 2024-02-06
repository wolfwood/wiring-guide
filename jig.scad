
wire_width=1.2;
wire_mount_length=2;
wire_mount_width=1.8;

hs_pad=2.6;
hs_width=1.75;
hs_length=13.2-(2*hs_pad)+(2*wire_width);

hs_height=6.85;
hs_offset=2.2;
hs_lobe=4.65;

function wire_height(low,mid,high) =
  (is_undef(low) && is_undef(mid) && is_undef(high)) ||
  !is_undef(low)  ? hs_height/2 - hs_offset/2 - wire_width/2 :
  !is_undef(mid)  ? hs_height/2 - wire_width/2 :
  !is_undef(high) ? hs_height/2 + hs_offset/2 - wire_width/2 :
  assert("wut?");

gap=.1;
max_z=wire_height(high=true)+2.5*wire_width;//6.92;

module hotswap_mount(){
  let(x=2.1,y=3,z=max_z) {
    translate([-x/2,hs_width/2,0]) cube([x,y,z]);
    let(x2=hs_length-wire_mount_width*2-wire_width,y2=wire_mount_length+gap) {
      translate([-x2/2,-y2 -hs_width/2,0]) cube([x2,y2,z]);
      let(z=hs_height-hs_lobe) translate([x/2,-y2-hs_width/2,0]) cube([(hs_length-x)/2,y+y2+hs_width,z]);
    }
  }
}

module wire_mount_rounded(wires=1,low,mid,high,left=true,right=true){
  floor = wire_height(low,mid,high);

  let(x=wire_mount_width,y=wire_mount_length,z=floor+2.5*wire_width, wire_width=wires*wire_width) {
    translate([wire_width/2+x/2,0,0]) linear_extrude(is_undef(mid) && is_undef(high) ? max_z : z) hull() {
      translate([0,y/2-x/2,0]){
        if(right){
          translate([x/4,0,0]) square([x/2,x],center=true);
        }
        circle($fn=60,d=x);
      }
      translate([0,-(y/2-x/2),0]) {
        if (right){
          translate([x/4,0,0]) square([x/2,x],center=true);
        }
        circle($fn=60,d=x);
      }
    }

    translate([-(wire_width/2+x/2),0,0]) linear_extrude(z) hull() {
      translate([0,wire_mount_length/2-x/2,0]) {
        if(left){
          translate([-x/4,0,0])square([x/2,x],center=true);
        }
        circle($fn=60,d=x);
      }
      translate([0,-(wire_mount_length/2-x/2),0]) {
        if (left){
          translate([-x/4,0,0]) square([x/2,x],center=true);
        }
        circle($fn=60,d=x);
      }
    }

    let(x=wire_width+x) translate([-x/2,-y/2,0]) cube([x,y,floor]);
  }
}

module ribbon_divider(angle=60,length=3,wires=4){
  ratio=tan(angle);
  distance=length/2/ratio;

  translate([sqrt(wires) == floor(sqrt(wires)) ? 0 :
	     (wires/2 - floor(sqrt(wires))^2) * wire_width * (is_undef($mirror) || !$mirror ? 1 : -1),
	     -wire_mount_length/2/*-wire_width/2*/,0]) wire_mount_rounded(wires,mid=true);

  translate([0,wire_width*(floor(sqrt(wires))^2)/2,0])
    linear_extrude(wire_height(mid=true)+wire_width*2.5)
    polygon([[0,0],
	     [ length/2, distance],
	     [-length/2, distance] ]);

}

module hotswap_jig(){
  let(angle=60,
      ratio=tan(angle), distance=hs_length/2/ratio,
      circle_corner=[(wire_mount_width/2) - (cos(angle)*wire_mount_width/2),
		     (wire_mount_width/2) - (sin(angle)*wire_mount_width/2)],
      bottom=-wire_width -distance -wire_mount_length -gap-hs_width/2-wire_mount_length/2
      ) {
    translate([0,wire_mount_length/2-bottom,0]){
      hotswap_mount();

      translate([-hs_length/2,-gap-hs_width/2-wire_mount_length/2,0]) wire_mount_rounded(right=true);
      translate([hs_length/2,-gap-hs_width/2-wire_mount_length/2,0]) wire_mount_rounded(high=true, left=true);

      translate([0,bottom,0]) wire_mount_rounded(2,mid=true);

      translate([0,-distance-wire_mount_length -gap-hs_width/2,0])
	linear_extrude(max_z) polygon([[0,0],
				       [-circle_corner.x + (hs_length-wire_width)/2, distance+circle_corner.y],
				       [ circle_corner.x - (hs_length-wire_width)/2, distance+circle_corner.y] ]);
    }
  }
}

module bifurcate(angle=30, little_spacing=4, big_spacing=14, wires=2^2) {
  assert(0 < $children && $children < 3);

  rotate([0,0, angle]) translate([0,(is_undef($mirror) || !$mirror ? big_spacing : 0) + little_spacing,0])
    children(is_undef($mirror) ? 0 : $children -1);
  rotate([0,0,-angle]) translate([0,(is_undef($mirror) || !$mirror ? 0 : big_spacing) + little_spacing,0])
    children(is_undef($mirror) ? $children -1 : 0);

  ribbon_divider(angle,2.8216, wires);
}

module plate(z=1.4, r=2) {
  children();

  translate([0,0,-z]) linear_extrude(z) offset(/*$fn=30,*/r=r/*,delta=1.5,chamfer=true*/) hull() projection() children();
}

$mirror=true;
plate() bifurcate(wires=6) {
  translate([-wire_width,0,0])
    bifurcate() hotswap_jig();
  hotswap_jig();
}
