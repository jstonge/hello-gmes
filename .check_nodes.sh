#!/bin/bash

check_nodes_left () {
		nodes_left=`squeue -u jstonge1 | wc -l`
        echo 'Checking how many nodes left..'
		echo $((nodes_left - 1))
		while [ $nodes_left -gt 1 ]
		do
			echo $((nodes_left - 1))
			sleep 5
			nodes_left=$(( `squeue -u jstonge1 | wc -l` ))
		done
		echo $((nodes_left - 1))
		echo 'All nodes are done'
}

check_nodes_left