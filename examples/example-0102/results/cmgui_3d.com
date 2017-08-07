#Read in the sequence of nodal positions.
for $i (1..5)
  {
	 $filename = sprintf("results/current_run/l160x120x120_n32x24x24_i1_s0/Example_%d.part0.exnode", $i);
	 
	 print "Reading $filename time $i\n";
	 gfx read node "$filename" time $i;
  }

#Read in the element description
gfx read elements results/current_run/l160x120x120_n32x24x24_i1_s0/Example.part0.exelem;

gfx define field xx add fields Displacement.1 Undeformed.x
gfx define field yy add fields Displacement.2 Undeformed.y
gfx define field zz add fields Displacement.3 Undeformed.z
gfx define field Deformed component xx yy zz


gfx define faces egroup "Region 1"
gfx modify g_element "Region 1" lines coordinate Deformed select_on material default selected_material default_selected
gfx modify g_element "Region 1" node_points coordinate Deformed glyph sphere General size "0.1*0.1*0.1" centre 0,0,0 font default select_on material default selected_material default_selected



######## opening window to visualize results##########

gfx cre win 1

gfx draw axes

gfx edit scene

gfx cre mat copper ambient 1 0.2 0 diffuse 0.6 0.3 0 specular 0.7 0.7 0.5 shininess 0.3


gfx modify g_element "/" general clear;

########creating creating a spectrum to display DEPENDENT_FIELD fields ##########

gfx create spectrum displacement_spectrum


######## Creating surface ########

#gfx modify g_element "/" surfaces coordinate Deformed tessellation default LOCAL select_on material black spectrum displacement_spectrum selected_material default_selected render_wireframe;

gfx modify spectrum displacement_spectrum linear reverse range -2 2 extend_above extend_below rainbow colour_range 0 1 component 1

######## Visulaize Elements #############
gfx modify g_element "Region 1" lines coordinate Deformed select_on material black selected_material default_selected;

########creating nodes with labels########

gfx modify g_element "/" node_points subgroup "Region 1" coordinate Deformed LOCAL glyph point general size "1*1*1" centre 0,0,0 font default select_on material black selected_material default_selected;

######## Creating another surface to show undeformed GEOMETRY ########

gfx modify g_element "/" surfaces coordinate Deformed tessellation default LOCAL select_on material black data Displacement.1 spectrum displacement_spectrum selected_material default_selected render_shaded;

########displaying color bar on the visualization window. ##########

gfx create colour_bar spectrum displacement_spectrum label_material black

gfx modify g_element "/" point glyph colour_bar general size "1*1*1" centre 0,0,0 select_on  normalised_window_fit_left;


gfx modify window 1 image view_all

gfx modify window 1 background colour 1 1 1

#gfx modify window 1 layout simple ortho_axes z -y eye_spacing 0.25 width 878 height 574

#gfx modify window 1 view parallel eye_point 80 60 407.98 interest_point 80 60 0 up_vector -0 1 -0 view_angle 40 near_clipping_plane 4.0798 far_clipping_plane 1457.98 relative_viewport ndc_placement -1 1 2 2 viewport_coordinates 0 0 1 1;

#gfx modify window 1 set transform_tool current_pane 1 std_view_angle 40 normal_lines no_antialias depth_of_field 0.0 fast_transparency blend_normal

gfx modify window 1 layout simple ortho_axes z -y eye_spacing 0.25 width 1715 height 1030;
gfx modify window 1 set current_pane 1;
gfx modify window 1 view parallel eye_point 330.892 219.709 275.544 interest_point 54.4465 60.4035 21.2862 up_vector -0.28531 0.920609 -0.266601 view_angle 48.7448 near_clipping_plane 4.0798 far_clipping_plane 1457.98 relative_viewport ndc_placement -1 1 2 2 viewport_coordinates 0 0 1 1;
gfx modify window 1 set transform_tool current_pane 1 std_view_angle 40 normal_lines no_antialias depth_of_field 0.0 fast_transparency blend_normal;


gfx set time 5

gfx print postscript file doc/figures/current_run.eps
exit
