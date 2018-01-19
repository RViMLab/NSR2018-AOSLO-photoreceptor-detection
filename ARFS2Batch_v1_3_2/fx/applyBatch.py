import os, sys, getopt, cPickle

# Command line arguments
argList = ["name=","ref=","dmb="]

name = ''; # Name of the video to which the batch parameters apply 
ref  = ''; # Reference frame
dmb  = ''; # Path and file name of the dmb being applied

try:
	opts, args = getopt.getopt(sys.argv[1:],'n:r:d:',argList)
except getopt.GetoptError:
	print 'blugh'
	sys.exit(2)
for opt, arg in opts:
	if opt in ('-n', "--name"):
		name = arg
	elif opt in ('-r', "--ref"):
		ref = arg
	elif opt in ('-d', "--dmb"):
		dmb = arg

possibleModalities = [
	'confocal',
	'det', # split, det works better
	'avg',
	'direct',
	'reflect',
	'binary',
        'visible',
        'ICG'
	]
nMods = len(possibleModalities)

def main():
	# Load .dmb

	fid = open(dmb,'r')
	pick = cPickle.load(fid)
	fid.close()

	# Change parameters
	pick['image_sequence_file_name'] = name
	pick['reference_frame']          = int(ref) -1 # 0-indexing
	lps  = pick['frame_strip_lines_per_strip']
	lbss = pick['frame_strip_lines_between_strips_start']
	pick['user_defined_suffix'] = '_ref_' + ref + '_lps_' + str(lps) + \
		'_lbss_' + str(lbss)

	# Handle secondary sequences
	if pick['secondary_sequences_file_names']:
		# First get the video number from name
		nameParts   = name.split('.')
		prefix      = nameParts[0]
		prefixParts = prefix.split('_')
		for m in possibleModalities:
			if m in prefixParts:
				indxMod = prefixParts.index(m)
				break
		indxVidNum = indxMod+1
		vidNum  = prefixParts[indxVidNum]
		# This assumes the vid number always follows the modality

		# Then change the video number in all the secondary sequences to
		# match the primary
		seq2  = pick['secondary_sequences_file_names']
		nSeq2 = len(seq2)
		for i in range(0,nSeq2):
			thisSeq     = seq2[i]
			nameParts   = thisSeq.split('.')
			prefix      = nameParts[0]
			prefixParts = prefix.split('_')
			for m in possibleModalities:
				if m in prefixParts:
					indxMod = prefixParts.index(m)
					break
			prefixParts[indxMod+1] = vidNum
			prefix = '_'.join(prefixParts)
			pick['secondary_sequences_file_names'][i] = prefix + '.avi'

	# Get .dmb path
	dmbParts = dmb.split(os.sep)
	dmbPath  = os.sep.join(dmbParts[:-1])

	# Make a new name
	nameParts = name.split('.')
	prefix    = nameParts[0]
	prefix   += '_ref_'+ref+'_lps_'+str(lps)+'_lbss_'+str(lbss)+'.dmb'
	newName   = dmbPath + os.sep + prefix
	print 'writing: ' + newName

	# Write new .dmb
	newfid = open(newName,'w')
	cPickle.dump(pick,newfid)
	newfid.close()


if __name__ == '__main__':
	main();
