#!/bin/sh

cmd="${1:-build}"

path="`readlink -f $0`"
prog="`basename $path`"

cur_d="`pwd`"
root_d="`dirname $path`"

# Const data
src_d="$root_d/src"
bibliography_d="$src_d"
templates_d="$src_d/templates"

# tmp data
build_d="$root_d/build"
out_d="$root_d/out"

out_file_prefix="main"

usage()
{
	echo "Usage: $prog <init|build|clean>"
}

do_log()
{
	[ -z "$stepcnt" ] && stepcnt=1
	echo "===> Step ${stepcnt}: $*..."
	stepcnt="`expr $stepcnt + 1`"
}

do_log_begin()
{
	[ -z "$stepcnt" ] && stepcnt=1
	echo -n "===> Step ${stepcnt}: $*... "
}

do_log_step()
{
	echo -n "$*.. "
}

do_log_end()
{
	echo ""
	stepcnt="`expr $stepcnt + 1`"
}

do_project_init()
{
	mkdir -p $src_d $dict_d $templates_d
}

do_build()
{
	local latex_cmd="latex -interaction=nonstopmode -output-directory $build_d"

	rm -rf $build_d
	mkdir -p $build_d $out_d

	cd $src_d

	do_log "Raw compile data"
	$latex_cmd main.tex >$build_d/latex.out 2>&1

	do_log "Compile bibliography references"
	biber --logfile biber \
		--input-directory $build_d \
		--output-directory $build_d \
		main.bcf >$build_d/biber.log 2>&1

	do_log "Recompile again to resolve preprocessed references"
	$latex_cmd main.tex >$build_d/latex2.out 2>&1

	#cd $build_d
	#$latex_cmd 	
	#latex -interaction=nonstopmode %.tex|latex -interaction=nonstopmode %.tex|xdvi %.dvi

	# Generate common used output formats
	do_log_begin "Generate final documents"

	do_log_step "ps"
	dvips -o $out_d/${out_file_prefix}.ps $build_d/${out_file_prefix}.dvi >$build_d/ps.log 2>&1

	do_log_step "pdf"
	#dvipdf $build_d/${out_file_prefix}.dvi $out_d/${out_file_prefix}.pdf >$build_d/pdf.log 2>&1

	do_log_end

	# Sort results to dirs
	do_sort_output

	cd $cur_d
}

do_sort_output()
{
	do_log_begin "Moving outs"
	for t in dvi ps pdf rtf; do
		do_log_step "$t"
		mv -f $build_d/*.${t} $out_d/ 2>/dev/null
	done
	do_log_end
}

case $cmd in
	init)
		do_project_init
	;;
	build)
		do_build
	;;
	*)
		usage
	;;
esac
