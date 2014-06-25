#define WORKGROUP_SIZE 1


inline void swap3(int2 *a, int2 *b)
{

    if ((*a).x > (*b).x)
    {
        int2 temp = *a;
        *a = *b;
        *b = temp;

    }


}

void bitonic_kernel(int2 *temp)
{
    //[[0,1],[2,3],[4,5],[6,7],[8,9],[10,11],[12,13],[14,15]]
    swap3(&temp[0], &temp[1]);
    swap3(&temp[2], &temp[3]);
    swap3(&temp[4], &temp[5]);
    swap3(&temp[6], &temp[7]);
    swap3(&temp[8], &temp[9]);
    swap3(&temp[10], &temp[11]);
    swap3(&temp[12], &temp[13]);
    swap3(&temp[14], &temp[15]);

    //[[0,3],[4,7],[8,11],[12,15]
    swap3(&temp[0], &temp[3]);
    swap3(&temp[4], &temp[7]);
    swap3(&temp[8], &temp[11]);
    swap3(&temp[12], &temp[15]);



    //[1,2],[5,6],[9,10],[13,14]
    swap3(&temp[1], &temp[2]);
    swap3(&temp[5], &temp[6]);
    swap3(&temp[9], &temp[10]);
    swap3(&temp[13], &temp[14]);

    //[[0,1],[2,3],[4,5],[6,7],[8,9],[10,11],[12,13],[14,15]]
    swap3(&temp[0], &temp[1]);
    swap3(&temp[2], &temp[3]);
    swap3(&temp[4], &temp[5]);
    swap3(&temp[6], &temp[7]);
    swap3(&temp[8], &temp[9]);
    swap3(&temp[10], &temp[11]);
    swap3(&temp[12], &temp[13]);
    swap3(&temp[14], &temp[15]);

    //[[0,2],[1,3],[4,6],[5,7], [8,10],[9,11],[12,14],[13,15]]

    swap3(&temp[0], &temp[2]);
    swap3(&temp[1], &temp[3]);
    swap3(&temp[4], &temp[6]);
    swap3(&temp[5], &temp[7]);
    swap3(&temp[8], &temp[10]);
    swap3(&temp[9], &temp[11]);
    swap3(&temp[12], &temp[14]);
    swap3(&temp[13], &temp[15]);

    //[[0,7],[1,6],[2,5],[3,4],[8,15],[9,14],[10,13],[11,12]]
    swap3(&temp[0], &temp[7]);
    swap3(&temp[1], &temp[6]);
    swap3(&temp[2], &temp[5]);
    swap3(&temp[3], &temp[4]);
    swap3(&temp[8], &temp[15]);
    swap3(&temp[9], &temp[14]);
    swap3(&temp[10], &temp[13]);
    swap3(&temp[11], &temp[12]);


    //[[0,1],[2,3],[4,5],[6,7],[8,9],[10,11],[12,13],[14,15]]
    swap3(&temp[0], &temp[1]);
    swap3(&temp[2], &temp[3]);
    swap3(&temp[4], &temp[5]);
    swap3(&temp[6], &temp[7]);
    swap3(&temp[8], &temp[9]);
    swap3(&temp[10], &temp[11]);
    swap3(&temp[12], &temp[13]);
    swap3(&temp[14], &temp[15]);



    //[[0,15],[1,14],[2,13],[3,12],[4,11],[5,10],[6,9],[7,8]]
    swap3(&temp[0], &temp[15]);
    swap3(&temp[1], &temp[14]);
    swap3(&temp[2], &temp[13]);
    swap3(&temp[3], &temp[12]);
    swap3(&temp[4], &temp[11]);
    swap3(&temp[5], &temp[10]);
    swap3(&temp[6], &temp[9]);
    swap3(&temp[7], &temp[8]);
    //[[0,4],[1,5],[2,6],[3,7],[8,12],[9,13],[10,14],[11,15]]
    swap3(&temp[0], &temp[4]);
    swap3(&temp[1], &temp[5]);
    swap3(&temp[2], &temp[6]);
    swap3(&temp[3], &temp[7]);
    swap3(&temp[8], &temp[12]);
    swap3(&temp[9], &temp[13]);
    swap3(&temp[10], &temp[14]);
    swap3(&temp[11], &temp[15]);
    //[[0,2],[1,3],[4,6],[5,7],[8,10],[9,11],[12,14],[13,15]]
    swap3(&temp[0], &temp[2]);
    swap3(&temp[1], &temp[3]);
    swap3(&temp[4], &temp[6]);
    swap3(&temp[5], &temp[7]);
    swap3(&temp[8], &temp[10]);
    swap3(&temp[9], &temp[11]);
    swap3(&temp[12], &temp[14]);
    swap3(&temp[13], &temp[15]);
    //[[0,1],[2,3],[4,5],[6,7],[8,9],[10,11],[12,13],[14,15]]

    swap3(&temp[0], &temp[1]);
    swap3(&temp[2], &temp[3]);
    swap3(&temp[4], &temp[5]);
    swap3(&temp[6], &temp[7]);
    swap3(&temp[8], &temp[9]);
    swap3(&temp[10], &temp[11]);
    swap3(&temp[12], &temp[13]);
    swap3(&temp[14], &temp[15]);
}

__kernel
#ifdef FPGA
//__attribute__((num_compute_units(1)))
//__attribute__((task))
#endif
__attribute__((reqd_work_group_size(WORKGROUP_SIZE,1,1)))
void bitonicmergesort(__global int2* restrict  input_data,  __global int2* restrict  output_data)
{
    const unsigned group_offset = get_group_id(0)* 16;

    //printf("group_offset: %u\n", group_offset);

    int2 input[16];

    #pragma unroll
    for (unsigned i  =0 ; i  < 16; ++i)
    {
        input[i] = input_data[group_offset+i];

    }


    bitonic_kernel(&input[0]);

    #pragma unroll
    for (unsigned i  =0 ; i  < 16; ++i)
    {
        output_data[group_offset+i] = input[i];

    }















}
