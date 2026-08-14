## Bug 1: Missing `for`,`then` keyword in loop and if statement

**Symptom:**
syntax error near unexpected token `do'

**diagnostic command + output**
hassan@Hassan-T14:~/MyDevOpsBootCamp/task$ bash -n rotate_log.sh 
rotate_log.sh: line 4: syntax error near unexpected token `do'
rotate_log.sh: line 4: `log_dir=$2for f in $(ls $log_dir/*.log); do'

**Root cause:**
malformed `for-do` loop statement and `if-then` condition statment

**Fix:**
for f in $(ls $log_dir/*.log); do
  age=$(find $f -mtime +7) 
  if [ $age ]; then
  mv $f $archive_dir/
  count=$count+1
  fi
done
echo "Archived $count files"
---

## Bug 2: unsafe file iteration 

**Symptom:**
if $log_dir contains spaces, the script breaks unintended. 

**diagnostic command + output**
hassan@Hassan-T14:~/MyDevOpsBootCamp/task$ shellcheck rotate_log.sh 

In rotate_log.sh line 5:
for f in $(ls $log_dir/*.log); do
         ^------------------^ SC2045 (error): Iterating over ls output is fragile. Use globs.
              ^------^ SC2086 (info): Double quote to prevent globbing and word splitting.

**Root cause:**
$(ls $log_dir/*.log) re-splits filenames on whitespace and can be replaced by glob; varibale log_dir should be quoted to prevent globbing and splitting.


**Fix:**
for f in $"$log_dir"/*.log; do
---

## Bug 3: unquoted variables 

**Symptom:**
word splitting happens when variable contains space

**diagnostic command + output**
hassan@Hassan-T14:~/MyDevOpsBootCamp/task$ shellcheck rotate_log.sh 

In rotate_log.sh line 6:
  age=$(find $f -mtime +7) 
             ^-- SC2086 (info): Double quote to prevent globbing and word splitting.

Did you mean: 
  age=$(find "$f" -mtime +7) 


In rotate_log.sh line 7:
  if [ $age ]; then
       ^--^ SC2086 (info): Double quote to prevent globbing and word splitting.


**Root cause:**
filename,path and directory related variables are not quoted 

**Fix:**
 age=$(find "$f" -mtime +7) 
  if [ "$age" ]; then
  mv "$f" "$archive_dir/"
---

## Bug 4: Number of archived files is not counted as expected


**Symptom:**
script output is string concatenation in stead of real number.

**diagnostic command + output**
+ mv /home/hassan/tmp/logs/3.log /home/hassan/tmp/archive/
+ count=+1+1+1
+ for f in "$log_dir"/*.log
++ find /home/hassan/tmp/logs/4.log -mtime +7
+ age=/home/hassan/tmp/logs/4.log
+ '[' /home/hassan/tmp/logs/4.log ']'
+ mv /home/hassan/tmp/logs/4.log /home/hassan/tmp/archive/
+ count=+1+1+1+1
+ echo 'Archived +1+1+1+1 files'
Archived +1+1+1+1 files

**Root cause:**
count=$count+1 is string concatenation

**Fix:**
count=$(($count + 1))
---