// BlackRoad Universal Blade Sled (OpenSCAD) // This generates a 3D printable "drawer" for your Monolith. // It is parametric - change the dimensions to fit a Luckfox, ESP32, or Milk-V.
// --- Dimensions of your Chip (Default: Luckfox Pico) --- chip_width = 21; chip_length = 51; chip_height = 10; // Clearance for components
// --- Blade Settings --- wall_thickness = 2; blade_length = 80; // Total depth of the Monolith handle_size = 15;
module blade() { difference() { // Main Body union() { // The Sled Floor cube([chip_width + (wall_thickness*2), blade_length, 2]);
        // The Side Walls
       translate([0, 0, 0])
           cube([wall_thickness, blade_length, chip_height]);
       translate([chip_width + wall_thickness, 0, 0])
           cube([wall_thickness, blade_length, chip_height]);
           
       // The Handle (Front) with Grip
       translate([0, -handle_size, 0]) {
           cube([chip_width + (wall_thickness*2), handle_size, chip_height]);
           // Grip texture
           for(i=[0:3:handle_size-2]) {
               translate([0, i, chip_height])
                   cube([chip_width + (wall_thickness*2), 1, 1]);
           }
       }
   }
   
   // --- Cutouts ---
   
   // Airflow Holes (Hex pattern usually best, using slots for simplicity)
   for(i=[10:10:blade_length-10]) {
       translate([wall_thickness + 2, i, -1])
           cube([chip_width - 4, 5, 4]);
   }
   
   // Power Wire Channels (Back)
   translate([wall_thickness + 2, blade_length - 5, -1])
       cube([3, 10, 5]); // Positive
   translate([chip_width + wall_thickness - 5, blade_length - 5, -1])
       cube([3, 10, 5]); // Ground
       
   // Status LED Light Pipe Hole (Front Handle)
   translate([(chip_width/2)+wall_thickness - 1.5, -handle_size-1, chip_height/2])
       cube([3, handle_size+2, 3]);
}

}
// Render blade();
// --- Instructions --- // 1. Measure your chip (Milk-V, Luckfox, etc). // 2. Adjust 'chip_width' and 'chip_length' variables above. // 3. Render (F6) and Export as STL. // 4. Print in PLA/PETG. // 5. Slide chip in (use double-sided tape or hot glue for "No Solder" fit).