
wire_width=1.2;
wire_mount_length=4;
wire_mount_width=1.8;

hs_pad=2.6;
hs_width=1.75;
hs_length=13.2-(2*hs_pad)+(2*wire_width);

hs_height=6.85;
hs_offset=2.2;
hs_lobe=4.65;


// for multi socket jigs
angle=15;
little_spacing=3.3;
big_spacing=16;

sockets=4;

if (is_undef($empty))
  magnet_jig(sockets);

function wire_height(low,mid,high) =
  (is_undef(low) && is_undef(mid) && is_undef(high)) ||
  !is_undef(low)  ? hs_height/2 - hs_offset/2 - wire_width/2 :
  !is_undef(mid)  ? hs_height/2 - wire_width/2 :
  !is_undef(high) ? hs_height/2 + hs_offset/2 - wire_width/2 :
  assert("wut?");

gap=.1;
max_z=wire_height(high=true)+2.5*wire_width;//6.92;
mid_z=wire_height(mid=true)+2.5*wire_width;

module hotswap_mount(){
  let(x=2.1,y=3,z=max_z) {
    translate([-x/2,hs_width/2,0]) cube([x,y,z]);
    let(x2=hs_length-wire_mount_width*2-wire_width,y2=wire_mount_length+gap) {
      translate([-x2/2,-y2 -hs_width/2,0]) cube([x2,y2,z]);
      let(z=hs_height-hs_lobe) translate([x/2,-y2-hs_width/2,0]) cube([(hs_length-x)/2,y+y2+hs_width,z]);
    }
  }
}

module wire_mount_rounded(wires=1,low,mid,high,left=true,right=true,clasp=false){
  floor = wire_height(low,mid,high);

  let(x=wire_mount_width,y=wire_mount_length,z=floor+2.5*wire_width, wire_width=wires*wire_width) {
    translate([wire_width/2+x/2,0,0]){
      linear_extrude(is_undef(mid) && is_undef(high) ? max_z : z) hull() {
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

      if(clasp)
	translate([0,y/2, max(z,mid_z)-2]) rotate([90,0,0]) linear_extrude(y) polygon([[0,0],[0,2],[-2,2]]);
    }

    translate([-(wire_width/2+x/2),0,0]) {
      linear_extrude(max(z,mid_z)) hull() {
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

      if(clasp)
	translate([0,y/2, max(z,mid_z)-2]) rotate([90,0,0]) linear_extrude(y) polygon([[0,0],[0,2],[2,2]]);
    }

    let(x=wire_width+x) translate([-x/2,-y/2,0]) cube([x,y,floor]);
  }
}

module ribbon_divider(angle=2*angle,length=3,wires=4){
  ratio=tan(angle);
  distance=length/2/ratio;

  reflect = (is_undef($mirror) || !$mirror) ? 1 : -1;

  translate([ (2-wires/2) * wire_width * reflect,
	     -wire_mount_length/2,0]) wire_mount_rounded(wires,mid=true, clasp=true);

  linear_extrude(wire_height(mid=true)+wire_width*2.5)
    hull(){
    translate([wire_width*2*reflect,0,0])
      rotate([0,0,-angle*reflect])
      translate([-wire_width*2*reflect,0,0])
      rotate([0,0,angle*reflect])
      polygon([[0,0],
	       [ length/2, distance],
	       [-length/2, distance] ]);

    translate([-wire_width*(wires-2)*reflect,0,0])
      rotate([0,0,angle*reflect])
      translate([wire_width*(wires-2)*reflect,0,0])
      rotate([0,0,-angle*reflect])
      polygon([[0,0],
	       [ length/2, distance],
	       [-length/2, distance] ]);
  }
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

module bifurcate(angle=angle, wires=2^2, divider=true) {
  assert(0 < $children && $children < 3);

  reflect = is_undef($mirror) || !$mirror;

  left_wires = reflect ? wires-2 : 2;
  right_wires = reflect ? 2 : wires-2;

  // assume a single child is centered, rather than pre-positioned
  if ($children == 1) {
    translate([-left_wires * wire_width,0,0])
      rotate([0,0, angle])
      translate([left_wires/2 * wire_width, (reflect ? big_spacing : 0) + little_spacing, 0])
      children();

    translate([right_wires * wire_width,0,0])
      rotate([0,0, -angle])
      translate([-right_wires/2 * wire_width, (!reflect ? big_spacing : 0) + little_spacing, 0])
      children();
  } else {
    translate([-left_wires * wire_width,0,0])
      rotate([0,0, angle])
      translate([(left_wires - 2) * wire_width, reflect ? big_spacing : little_spacing, 0])
      children(reflect ? 0 : $children -1);

    translate([right_wires * wire_width,0,0])
      rotate([0,0,-angle])
      translate([(right_wires - 2) * -wire_width, reflect ? little_spacing  : big_spacing, 0])
      children(reflect ? $children -1 : 0);
  }

  if (divider)
    ribbon_divider(angle,2.8216, wires);
}

module plate(z=1.4, r=2) {
  children();

  translate([0,0,-z]) linear_extrude(z) offset(/*$fn=30,*/r=r/*,delta=1.5,chamfer=true*/) hull() projection() children();
}

module magnet_jig(sockets=3,
                  // position relative to a 2 socket jig
                  magnet = [(is_undef($mirror) || !$mirror ? -1 : 1) * 7.5,8.3,0],
                  mag_depth=.8,
                  mag_dia=12,
                  mag_h=3){
  assert(is_num(sockets) && sockets >= 2);

  difference() {
    plate() {
      recursive_jig(sockets = sockets);

      recursive_magnet(sockets=sockets,
                       magnet=magnet, mag_depth=mag_depth, mag_dia=mag_dia, mag_h=mag_h);
    }

    recursive_magnet(sockets=sockets, punch=true,
                     magnet=magnet, mag_depth=mag_depth, mag_dia=mag_dia, mag_h=mag_h);
  }

  if($preview){
    color("silver")
      recursive_magnet(sockets=sockets, preview=true,
                       magnet=magnet, mag_depth=mag_depth, mag_dia=mag_dia, mag_h=mag_h);
  }

  jig_wires(sockets = sockets);
}

module recursive_jig(sockets) {
  chirality = is_undef($mirror) || !$mirror ? -1 : 1;

  if (sockets == 2) {
    bifurcate() hotswap_jig();
  } else {
    bifurcate(wires=sockets*2) {
      recursive_jig(sockets = sockets - 1);
      //align left or right
      translate([chirality * wire_width,0,0]) hotswap_jig();
    }
  }
}

module recursive_magnet(sockets, punch=false, preview=false,
                  magnet,
                  mag_depth,
                  mag_dia,
                  mag_h) {
  if (sockets == 2) {
    translate(magnet) {
      if (preview) {
        translate([0,0,-mag_depth]) cylinder(d=mag_dia,h=mag_h);
      } else {
        if (!punch) {
          cylinder(d=mag_dia+2,h=1);
        } else {
          translate([0,0,-mag_depth]) cylinder($fn=60,d=mag_dia+.1,h=mag_h);
          cylinder(d=5,h=20,center=true);
        }
      }
    }
  } else {
    bifurcate(wires=sockets*2, divider=false) {
      recursive_magnet(sockets = sockets - 1, punch=punch, preview=preview,
                       magnet=magnet, mag_depth=mag_depth, mag_dia=mag_dia, mag_h=mag_h);
      // empty placeholder, so bifurcate doesn't clone the magnet
      cube([0,0,0]);
    }
  }
}

module jig_wires(sockets=3) {
  mirror([(is_undef($mirror) || !$mirror) ? 0 : 1, 0,0]) if($preview){
    recursive_wires(sockets = sockets);

    translate([-(sockets -1) *2*wire_width,0,0])
      wires(sockets*2,back=true);
  }
}

module recursive_wires(sockets = 3) {
  assert(sockets >= 1);
  l_jig = little_spacing + wire_mount_length + 1;

  wires(2,l=l_jig,a=angle);

  if (sockets == 2) {
    wires(2,l=big_spacing+l_jig,a=-angle);
  } else {
    wires((sockets-1)*2,l=big_spacing,a=-angle);

    translate([-2*(sockets-1)*wire_width,0,0])
    rotate([0,0,angle])
      translate([2*(sockets-2)*wire_width,big_spacing,0])
      recursive_wires(sockets-1);
  }
}

module wire(l=14+wire_mount_length, back=false){
  color("grey",.4)
  translate([wire_width/2,0,wire_width/2+wire_height(mid=1)])
    rotate([90*(back?1:-1),0,0])
    cylinder($fn=30, d=wire_width, h=l);
}

module wires(n=2,l=13+wire_mount_length, a=0, t=[0,0,0], back=false){
  if(a < 0) {
    translate([-wire_width*n,0,0])
      rotate([0,0,a*(back?1:-1)])
      translate([wire_width*n,0,0])
      for(i=[1:n]){
	translate([-wire_width*i,0,0]+t)
	  wire(l=l,back=back);
      }

  } else {
    translate([wire_width*n *(a < 0 ? -1 : 1),0,0])
      rotate([0,0,a*(back?1:-1)])
      translate([-wire_width*n*(a < 0 ? -1 : 1),0,0])
      for(i=[0:n-1]){
	translate([wire_width*i,0,0])
	  wire(l=l,back=back);
      }
  }
}
