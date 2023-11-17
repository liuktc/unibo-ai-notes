#! /bin/bash

# 
# Commit based .tex compiling
# 

if [ $# -eq 0 ]; then
	echo "Missing output directory"
	exit -1
fi

shopt -s globstar

out_dir=`realpath $1`
hash_file="$out_dir/.hash"
work_dir=`realpath src`

mkdir -p $out_dir
touch $hash_file

# $1: path of the directory
getDirLastHash () {
    path="$1"
    echo `awk -F"," "\\$1 == \"$path\" { print \\$2 } " $hash_file`
}

updateHashes() {
    cd $work_dir
    echo "ainotes.cls,`git log -n 1 --format='%h' ./ainotes.cls`" > $hash_file
    for f in **/[!_]*.tex; do
        f_dir=$(dirname $f)
        echo "$f_dir,`git log -n 1 --format='%h' $f_dir`" >> $hash_file
    done
}


cd $work_dir

old_class_hash=`getDirLastHash "ainotes.cls"`
curr_class_hash="$(git log -n 1 --format='%h' ./ainotes.cls)"

for f in **/[!_]*.tex; do
    f_dir=$(dirname $f)
    f_base=$(basename $f)
    f_nameonly="${f_base%.*}"
    old_hash=`getDirLastHash "$f_dir"`
    curr_hash="$(git log -n 1 --format='%h' $f_dir)"

    # Nothing to update
    if [[ $old_hash == $curr_hash && $old_class_hash == $curr_class_hash ]]; then
        echo "Skipping $f_dir"
        continue
    fi


    cd ${f_dir};

    # Insert last update date
    last_update=$(git log -1 --pretty="format:%ad" --date="format:%d %B %Y" .)
    cp --remove-destination $(readlink ainotes.cls) ainotes.cls
    sed -i "s/PLACEHOLDER-LAST-UPDATE/${last_update}/" ainotes.cls

    latexmk -pdf -jobname=${f_nameonly} ${f_base}
    mkdir -p $out_dir/$f_dir
    mv ${f_nameonly}.pdf $out_dir/${f_dir}/.
    cd $work_dir
done

updateHashes