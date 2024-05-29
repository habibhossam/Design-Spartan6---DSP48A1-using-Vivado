vlib work
vlog *.v     
vsim -voptargs=+acc work.project1_tb      
add wave *    
run -all
#quit -sim