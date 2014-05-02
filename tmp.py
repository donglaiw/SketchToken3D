import sys

cc=int(sys.argv[1])

if cc==0:
    a= open('U_gabor3d.m')
    b = a.readlines()
    b = b[0]
    a.close()
    aa= open('U_gabor3d.m2','w')    
    l2 = 1    
    cc = 0
    while l2>=0:
    	l1 = b.find('%')
    	l2 = b[l1+1:].find('%')
    	aa.write(b[:l1+l2]+'\n')
    	print l1,l2,b[:l1+l2]
    	b = b[l1+l2:]    	
    	cc+=1
    	if cc==-5:
    		break
	
	#aa.write(b+'\n')
    aa.close()