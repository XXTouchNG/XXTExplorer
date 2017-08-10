# Usage:
#
#   python localized.py > Localization.strings
#
# This script should be placed in the Xcode project folder. It will read all .m files 
# and extract all NSLocalizedString and Localized codes.
#
# Differences between this and genstrings from Apple tool:
# - Group the strings by the filename (instead of alphabetically)
# - Scan for "Localized" code, which is a Macro for NSLocalizedString with recursive replacement and optional comment
#
# This script is heavily copied from: https://github.com/dunkelstern/Cocoa-Localisation-Helper

import os, re, subprocess
import fnmatch

def fetch_files_recursive(directory, extension):
    matches = []
    for root, dirnames, filenames in os.walk(directory):
      for filename in fnmatch.filter(filenames, '*' + extension):
          matches.append(os.path.join(root, filename))
    return matches
    

# prepare regexes
localizedStringComment = re.compile('NSLocalizedString\(@"([^"]*)",\s*@"([^"]*)"\s*\)', re.DOTALL)
localizedStringNil = re.compile('NSLocalizedString\(@"([^"]*)",\s*nil\s*\)', re.DOTALL)
localized = re.compile('Localized\(@"([^"]*)"\)', re.DOTALL)

# get string list
uid = 0
strings = []
for file in fetch_files_recursive('.', '.m'):
    with open(file, 'r') as f:
        content = f.read()
        for result in localizedStringComment.finditer(content):
            uid += 1
            strings.append((result.group(1), result.group(2), file, uid))
        for result in localizedStringNil.finditer(content):
            uid += 1
            strings.append((result.group(1), '', file, uid))
        for result in localized.finditer(content):
            uid += 1
            strings.append((result.group(1), '', file, uid))

# find duplicates
duplicated = []
filestrings = {}
for string1 in strings:
    dupmatch = 0
    for string2 in strings:
        if string1[3] == string2[3]:
            continue
        if string1[0] == string2[0]:
            if string1[2] != string2[2]:
                dupmatch = 1
            break
    if dupmatch == 1:
        dupmatch = 0
        for string2 in duplicated:
            if string1[0] == string2[0]:
                dupmatch = 1
                break
        if dupmatch == 0:
            duplicated.append(string1)
    else:
        dupmatch = 0 
        if string1[2] in filestrings:
            for fs in filestrings[string1[2]]:
                if fs[0] == string1[0]:
                    dupmatch = 1
                    break
        else:
            filestrings[string1[2]] = []
        if dupmatch == 0:
            filestrings[string1[2]].append(string1)

# output filewise
for key in filestrings.keys():
    print '/*\n * ' + key + '\n */\n'

    strings = filestrings[key]
    for string in strings:
        if string[1] == '':
            print '"' + string[0] + '" = "' + string[0] + '";'
            print
        else:
            print '/* ' + string[1] + ' */'
            print '"' + string[0] + '" = "' + string[0] + '";'
            print
    print '\n\n\n\n\n'


print '\n\n\n\n\n'
print '/*\n * SHARED STRINGS\n */\n'

# output duplicates
for string in duplicated:
    if string[1] == '':
        print '"' + string[0] + '" = "' + string[0] + '";'
        print
    else:
        print '/* ' + string[1] + ' */'
        print '"' + string[0] + '" = "' + string[0] + '";'
        print
