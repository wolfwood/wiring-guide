
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

      if(clasp && (!is_undef($mirror) && $mirror))
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

      if(clasp && (is_undef($mirror) || !$mirror))
	translate([0,y/2, max(z,mid_z)-2]) rotate([90,0,0]) linear_extrude(y) polygon([[0,0],[0,2],[2,2]]);
    }

    let(x=wire_width+x) translate([-x/2,-y/2,0]) cube([x,y,floor]);
  }
}

module ribbon_divider(angle=2*angle,length=3,wires=4){
  ratio=tan(angle);
  distance=length/2/ratio;

  reflect = (is_undef($mirror) || !$mirror) ? 1 : -1;

  translate([sqrt(wires) == floor(sqrt(wires)) ? 0 :
	     (wires/2 - floor(sqrt(wires))^2) * wire_width * reflect,
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

module bifurcate(angle=angle, wires=2^2) {
  assert(0 < $children && $children < 3);

  reflect = is_undef($mirror) || !$mirror;

  left_wires = reflect ? wires-2 : 2;
  right_wires = reflect ? 2 : wires-2;

  translate([-(left_wires)*wire_width,0,0])
    rotate([0,0, angle])
    translate([(left_wires)/2*wire_width, reflect ? big_spacing + ($children == 1 ? little_spacing : 0) : little_spacing, 0])
    children(reflect ? 0 : $children -1);

  translate([right_wires * wire_width,0,0]) rotate([0,0,-angle]) translate([right_wires/2 * -wire_width, reflect ? little_spacing  : big_spacing + ($children==1 ? little_spacing : 0), 0])
    children(reflect ? $children -1 : 0);

  ribbon_divider(angle,2.8216, wires);
}

module plate(z=1.4, r=2) {
  children();

  translate([0,0,-z]) linear_extrude(z) offset(/*$fn=30,*/r=r/*,delta=1.5,chamfer=true*/) hull() projection() children();
}

$mirror=false;

module magnet_jig(sockets=3,
                  magnet = [(is_undef($mirror) || !$mirror ? -1 : 1) * 16,22,0],
                  mag_depth=.8,
                  mag_dia=12,
                  mag_h=3){
  assert(is_num(sockets) && sockets >= 2);

  difference() {
    plate() {
      recursive_jig(sockets = sockets);

      translate(magnet) cylinder(d=mag_dia+2,h=1);
    }

    translate(magnet+[0,0,-mag_depth]) cylinder($fn=60,d=mag_dia+.2,h=mag_h);
    translate(magnet) cylinder(d=5,h=20,center=true);
  }

  if($preview){
    color("grey") translate(magnet-[0,0,mag_depth]) cylinder(d=mag_dia,h=mag_h);
  }
}

module recursive_jig(sockets) {
  if (sockets == 2) {
    bifurcate() hotswap_jig();
  } else {
    bifurcate(wires=sockets*2) {
      recursive_jig(sockets = sockets - 1);
      hotswap_jig();
    }
  }
}

magnet_jig();

mirror([(is_undef($mirror) || !$mirror) ? 0 : 1, 0,0]) if($preview){
  translate([-4*wire_width,0,0])
    wires(6,back=true);

  l_jig = little_spacing + wire_mount_length + 1;

  wires(2,l=l_jig,a=angle);

  l_trunk1 = big_spacing;
  wires(4,l=l_trunk1,a=-angle);

  translate([-4*wire_width,0,0])
    rotate([0,0,angle])
    translate([2*wire_width,l_trunk1,0])
    wires(2,l=l_jig,a=angle);

  l_trunk2 = big_spacing+l_jig;
  translate([-4*wire_width,0,0])
    rotate([0,0,angle])
    translate([2*wire_width,l_trunk1,0])
    wires(2,l=l_trunk2,a=-angle);

  echo(str(" Row 1: ", l_jig, "mm", ", effective: 0 mm"));
  echo(str(" Row 2: ", l_trunk1+l_jig, "mm, effective: ", l_trunk1, "mm"));
  echo(str(" Row 3: ", l_trunk1+l_trunk2, "mm, effective: ",  l_trunk2-l_jig,"mm"));
}


module wire(l=14+wire_mount_length, back=false){
  color("grey",.2)
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
