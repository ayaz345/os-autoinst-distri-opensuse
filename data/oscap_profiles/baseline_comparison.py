#!/usr/bin/python3

# Extract baseline and save baseline in a hash map
def extractBaseline(file):
    stdout = open(file, "r+")
    line = stdout.readline()
    ret = {}
    keys = []
    values = []
    while line:
        if line.__contains__('Title'):
            line = stdout.readline()
            title = line.strip()
            keys.append(title)
            line = stdout.readline()
        elif line.__contains__('Result'):
            line = stdout.readline()
            result = line.strip()
            values.append(result)
            line = stdout.readline()
        else:
            line = stdout.readline()

    for key, value in zip(keys, values):
        ret.__setitem__(key, value)
    return ret


# Extract baselines that changed after remediation, since this log contains baselines before and after remediation
def getRemediatedBaseline(file_input, file_output):
    tag = 'Starting Remediation'
    tag_found = False
    with open(file_input) as in_file:
        with open(file_output, 'w') as out_file:
            for line in in_file:
                if tag_found:
                    out_file.write(line)

                elif line.__contains__(tag):
                    tag_found = True


getRemediatedBaseline("oscap_xccdf_remediate-stdout", "remediate-stdout-reformatted")
baseline_orig = extractBaseline("oscap_xccdf_eval-stdout")
baseline_remediated = extractBaseline("remediate-stdout-reformatted")

# Write result log and record basic change info
count_fail_to_fixed = 0
count_fail_to_error = 0
count_fail_to_fail = 0

baseline_result = open('baseline_comparison_result', 'w')
baseline_result.write(
    f'Total counts of evaluated baseline: {len(baseline_orig)}' + '\n'
)
baseline_result.write(
    f'Total counts of remediated baseline: {len(baseline_remediated)}' + '\n'
)
baseline_result.write('\n')
baseline_result.write('--- Baseline Change Log After Remediation---\n')

for k, v in baseline_remediated.items():
    baseline_result.write(k + ':\n')
    status_orig = baseline_orig.get(k)
    baseline_result.write(f'{status_orig} -> {v}' + '\n')
    baseline_result.write('\n')

    if v == 'error':
        count_fail_to_error += 1
    elif v == 'fail':
        count_fail_to_fail += 1

    elif v == 'fixed':
        count_fail_to_fixed += 1
# Output basic remediation stats
print(f'Total baseline remediated: {len(baseline_remediated)}')
print('Remediation change counts: ')
print(f'fail -> fixed: {str(count_fail_to_fixed)}')
print(f'fail -> error: {str(count_fail_to_error)}')
print('fail -> fail: ', count_fail_to_fail)

