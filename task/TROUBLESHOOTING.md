## Bug 1: Missing `then` keyword in if statement

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
--