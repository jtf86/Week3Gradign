#!/usr/bin/env bash

# INSTRUCTIONS FOR STUDENTS

# Students will need to put their database files in the top level of their project and name them to match this pattern "firstName_lastName.sql" and "firstName_LastName_test.sql". The test file should have the same name as the production file with "_test" at the end.

# CODE FOR TEACHERS

# Change the output to the name of the file where you'd like to store the data. Keep the ../ so it saves to the directory you're in (unless you want it in another directory).

OUTPUT=c_week_3_code_review.txt
FAILS=fails.txt
FAIL="false"
DBNAME=""
TESTDBNAME=""
HASMAINSQL="false"
HASTESTSQL="false"
DBEXT=".sql"


# gets custom name of student's database, prints to output if student did not put sql file in top level of directory
db_get_name(){
  for i in *.sql; do
    if [ ${i} != *_test.sql ];then
      DBNAME="${i/$DBEXT}"
      TESTDBNAME="${DBNAME}_test"
      HASMAINSQL="true"
    fi
    if [ ${i} == *_test.sql ];then
      HASTESTSQL="true"
    fi
  done
  if [ ${HASMAINSQL} == "false" ];then
    printf "\n FAIL: main sql file was not present in top level of directory" >> ../"$OUTPUT"
    FAIL="true"
  fi
  if [ ${HASTESTSQL} == "false" ];then
    printf "\n FAIL: test sql file was not present in top level of directory" >> ../"$OUTPUT"
    FAIL="true"
  fi
}

# restores both csproj files
restore_projects() {
  cd HairSalon
  dotnet restore
  cd ../HairSalon.Tests
  dotnet restore
  cd ..
}

# sets up real database and test database using sqlcmd and SSMS, will add line to output if student did not include instructions for creating their test db
db_setup() {
  /Applications/MAMP/Library/bin/mysql --host=localhost -uroot -proot -e "CREATE DATABASE IF NOT EXISTS ${DBNAME} DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;
  USE '${DBNAME}';"
  /Applications/MAMP/Library/bin/mysql --host=localhost -uroot -proot < ${DBNAME}.sql
  /Applications/MAMP/Library/bin/mysql --host=localhost -uroot -proot -e "CREATE DATABASE IF NOT EXISTS ${TESTDBNAME} DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;
  USE '${TESTDBNAME}';"
  /Applications/MAMP/Library/bin/mysql --host=localhost -uroot -proot ${TESTDBNAME} < ${TESTDBNAME}.sql
}


# Function to check passing tests. The chained grep command will grep lines that have the specified pattern. For C#, only one line has the pattern "Total: ,", and it will result in an output like this: "23 examples, 0 failures." Change the part before | depending on the command for running tests, and change the pattern as needed.
check_tests() {
  FAILED="Failed: 0"
  printf "Tests:\n" >> ../"$OUTPUT"
  cd HairSalon.Tests
  TESTOUTPUT="$(dotnet test | grep --line-buffered "Total ")"
  printf "${TESTOUTPUT}" >> ../../"$OUTPUT"
  if [ "${TESTOUTPUT/$FAILED}" == "${TESTOUTPUT}" ]; then
    FAIL="true"
    printf "FAIL: not all tests are passing \n" >> ../../"$OUTPUT"
  fi
  cd ..
}

# Function to check total commits and time of first and last commits. This should work universally, but only checks the master branch and no other branches.
check_commits() {
  printf "\n Total commits:\n"
  git rev-list --count master | tail -1
  printf "First commit:\n"
  git log|tail -5|grep --line-buffered "Date"
  printf "Last commit:\n"
  git log -1|grep --line-buffered "Date"
}

# Function to check if README exists. Should work universally.
readme_exists() {
  if [ ! -f README.md ]; then
    printf "FAIL: No README" >> ../"$OUTPUT"
  fi
}

CURRENTSTUDENT=""
ALTERNATE="isname"
for student in `cat students.txt`; do
  if [ "$ALTERNATE" = "isname" ]; then
    echo "the next student is $student"
    pwd
    mkdir $student
    CURRENTSTUDENT=${student}
    echo -n $student >> "$OUTPUT"
    ALTERNATE="repo"
  else
    git clone $student ${CURRENTSTUDENT}
    cd ${CURRENTSTUDENT}
    db_get_name
    printf "\n" >> ../"$OUTPUT"
    restore_projects
    if [ "$HASMAINSQL" = "true" ];then
      db_setup
      check_tests
    fi
    check_commits >> ../"$OUTPUT"
    readme_exists
    printf "\n" >> ../"$OUTPUT"
    ALTERNATE="isname"
    HASTESTSQL="false";
    HASMAINSQL="false";
    if "$FAIL" == "true"; then
      printf "\n ${CURRENTSTUDENT}" >> ../"$FAILS"
    fi
    FAIL="false"
    cd ..
  fi
done
