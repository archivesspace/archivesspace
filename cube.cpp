/*  C++ program to Find Cube of Number using MACROS  */

#include<iostream>
using namespace std;

#define CUBE(x) (x*x*x)

int main()
{
    int n,cube;

    cout<<"Enter any positive number :: ";
    cin>>n;

    cube=CUBE(n);

    cout<<"\nThe Cube of Entered Number [ "<<n<<" ] is :: [ "<<cube<<" ]\n";

    return 0;
}
