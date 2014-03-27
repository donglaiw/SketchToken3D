#include <mex.h>
#include <math.h>

double pixel_distance (int A_x,int A_y, int B_x, int B_y, int A_x_size,int A_y_size, int B_x_size,int B_y_size,double *img1, double *img2,int psz_h,int opt){
    double dist=0,temp_h,temp_v;
    int x,y,p1,p2;
    for(x=-psz_h;x<=psz_h;x++){
        for(y=-psz_h;y<=psz_h;y++)
        {
            if((A_x + x)>=0 && (A_y + y)>=0 && (A_x + x)<A_x_size && (A_y + y)<A_y_size
                    && (B_x + x)>=0 && (B_y + y)>=0 && (B_x + x)<B_x_size && (B_y + y)<B_y_size)
            {
                p1=  ((A_y + y) * A_x_size) + (A_x + x);
                p2= ((B_y + y) * B_x_size) + (B_x + x);
                temp_h =img1[p1] - img2[p2];
                switch(opt){
                    case 1:
                        dist+=temp_h*temp_h;
                        break;
                    case 2:
                        dist+=fabs(temp_h);
                        break;
                }
            }
        }
    }
    return dist;
}

void mexFunction(int nlhs, mxArray *plhs[], int nrhs,
        const mxArray *prhs[])
{
    
    double *img1,*img2;
    /*1) Read */
    img1= mxGetPr(prhs[0]);
    img2= mxGetPr(prhs[1]);
    int row = mxGetM(prhs[0]);
    int col = mxGetN(prhs[0]);
    int warprange= (int)mxGetScalar(prhs[2]);
    int psz_h= (int)mxGetScalar(prhs[3]);
    int step= (int)mxGetScalar(prhs[4]);
    int opt= (int)mxGetScalar(prhs[5]);
    
    /*2) IDM Algo*/
    double best_dis,*z,*dis;
    double temp;
    int x,y,xx,yy;
    
    int num_row = 1+(int)floor((float)(row-1)/(float)step);
    int num_col = 1+(int)floor((float)(col-1)/(float)step);
    //printf("col: %d,%d,%d,%d,%d\n",row,col,psz_h,num_row,num_col);/**/
    
    /* 3) Return map */
    plhs[0] =mxCreateDoubleMatrix(num_row,num_col,mxREAL);
    plhs[1] =mxCreateDoubleMatrix(num_row,num_col,mxREAL);
    z = mxGetPr(plhs[0]);
    dis = mxGetPr(plhs[1]);
    /*for each patch*/
    /**/
    int cc=0,best_pos,tmp_pos;
    for (y = 0; y <col; y+=step){
        for (x = 0; x <row; x+=step)
        {
            best_dis = DBL_MAX;
            best_pos = -1;
            tmp_pos = 0;
            for(yy=y-warprange;yy<=y+warprange;yy++){
            for(xx=x-warprange;xx<=x+warprange;xx++){                
                    if(xx >= 0 && yy >= 0 && xx < row && yy < col){
                        temp=pixel_distance (x, y, xx, yy, row,col,row,col,img1, img2, psz_h,opt);
                        if(temp<best_dis)
                        {
                            best_dis = temp;
                            best_pos = tmp_pos;
                        }
                    }
                    tmp_pos += 1;
                }
                if(best_dis==0){break;}
            }
		/*printf("%d,%d,%d\n",x,y,cc);*/
            z[cc]=best_pos;
            dis[cc]=best_dis;
            cc += 1;
        }
    }

}

