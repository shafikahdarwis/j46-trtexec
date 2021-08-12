#!/usr/bin/env bash

# Author : shafikah(nurshafikah.darwis@intel.com)
# -------------------------------------------------

import argparse
from itertools import groupby
import sys
import csv
import os
from datetime import datetime
import re # TODO:

os.system('clear')

ap = argparse.ArgumentParser()
ap.add_argument("-f", "--file", required=True,
	help="path to input data")
args = vars(ap.parse_args())
		
def all_equal(iterable):
	g = groupby(iterable)
	return next(g, True) and not next(g, False)
		
def clean_data(listing, stringName):
	""" """
	condition = all_equal(listing)
	if all_equal(listing):
		return listing[0]
	else:
		# exits the program 
		print("[ERROR] Required %s are abnormal..." % stringName)
		print("[ERROR] List of %s:" % stringName)
		print(listing)
		print("[ERROR] Please check the file!")
		sys.exit("[ERROR] Files may be corrupted...")


file = open(args["file"],"r")

Content = file.read()

formatRegex = re.compile(r'Format: \S*')
prototxtRegex = re.compile(r'Prototxt: \S*')
precisionRegex = re.compile(r'Precision: \S*')
iterationsRegex = re.compile(r'Iterations: \S*')
batchRegex = re.compile(r'Batch: \S*')
#throughputRegex = re.compile(r'throughput: \S* qps')
throughputRegex = re.compile(r'Throughput: \S* qps')
#latencyRegex = re.compile(r'mean: \S* ms \(end to end \S* ms\)')	# mean: 1.97473 ms (end to end 1.98649 ms)
latencyRegex = re.compile(r'\[I\] Latency: \w*\s*\D*\s*\S* ms, \w*\s*\D*\s*\S* ms, \w*\s*\D*\s*\S* ms, \w*\s*\D*\s*\S* ms, \D*\S*\D*\S* ms')	# Latency: min = 1.74683 ms, max = 2.82562 ms, mean = 1.85079 ms, median = 1.8269 ms, percentile(99%) = 2.4436 ms

list_of_format = formatRegex.findall(Content)
list_of_prototxt = prototxtRegex.findall(Content)
list_of_precision = precisionRegex.findall(Content)
list_of_iteration = iterationsRegex.findall(Content)
list_of_batch = batchRegex.findall(Content)
list_of_throughput = throughputRegex.findall(Content)
list_of_latency = latencyRegex.findall(Content)

usedFormat = clean_data(list_of_format, r'Format: \S*')
usedPrototxt = clean_data(list_of_prototxt, r'Prototxt: \S*')
usedPrecision = clean_data(list_of_precision, r'Precision: \S*')
usedIteration = clean_data(list_of_iteration, r'Iterations: \S*')

list_of_mean = []
for i in list_of_latency:
	meanRegex = re.compile(r'mean = \S* ms')
	mean = meanRegex.findall(i)
	list_of_mean.append(mean[0])

# Summary
print("*" * 15 + " SUMMARY " + "*" * 15)
print("Format: %s" % usedFormat[8::])
print("Prototxt: %s" % os.path.basename(usedPrototxt[10::]))
print("Precision: %s" % usedPrecision[11::])
print("Iteration: %s" % usedIteration[11::])
print("Batch (N):\tThroughput (qps):\tLatency -- Mean (ms)")

for (i, j, k) in zip(list_of_batch, list_of_throughput, list_of_mean):
	print("%s\t\t%s\t\t%s" % (i[7::], j[12:-3], k[6:-2]))

print("*" * 40)

path, folder = os.path.split(args["file"])
base = os.path.basename(args["file"])
now = datetime.now()
dt_string = now.strftime("%B %d, %Y %H:%M:%S")
newFilename = "Summary" + base[3:-4] + '.csv'
dirPath = os.path.sep.join([path, newFilename])

with open(dirPath, mode='w') as extract_file:
	extract_writer = csv.writer(
					extract_file, 
					delimiter=',', 
					quotechar='"', 
					quoting=csv.QUOTE_MINIMAL
					)

	extract_writer.writerow(["Format", usedFormat[8::]])
	extract_writer.writerow(["Prototxt", os.path.basename(usedPrototxt[10::])])
	extract_writer.writerow(["Precision", usedPrecision[11::]])
	extract_writer.writerow(["Iteration", usedIteration[11::]])
	extract_writer.writerow(["Batch (N)", "Throughput (qps)", "Latency (Mean) (ms)"])
	
	for (i, j, k) in zip(list_of_batch, list_of_throughput, list_of_mean):
		extract_writer.writerow([i[7::], j[12:-3], k[6:-2]])
		
print("[INFO] Extracted files were save in: %s" % newFilename)
