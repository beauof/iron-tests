here=$(pwd)
# run compare target for every example
for examplefolder in `ls -d example-*`
do
    cd $examplefolder/results
    python compare_solutions.py
    cd $here
done
pwd

# collect 'failed.tests' and 'results.summary' files from each example
rm -f ../failed.tests
for failedtests in `ls example-*/results/failed.tests`
do
    echo "Content of: $failedtests" >> ../failed.tests
    cat $failedtests >> ../failed.tests
    echo " " >> ../failed.tests
done
cat `ls example-*/results/results.summary` | awk '{s+=$3;t+=$5}END{print "Passed tests: " s " / " t}' | tee ../results.summary
