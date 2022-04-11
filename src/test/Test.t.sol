contract Test {
    mapping(uint256 => address) t;
    uint256 counter;

    address[] t2;

    uint256 num = 5;

    function test1() public {
        // t[0] = address(this);
        // // unchecked {
        // //     ++counter;
        // // }
        // t[1] = address(this);
        // t[2] = address(this);
        // unchecked {
        //     counter += 3;
        // }

        // t[1] = address(0);

        uint256 n = num;
        for (uint256 i; i < n; i++) t[i] = address(0);
    }

    function test2() public {
        for (uint256 i; i < num; i++) t[i] = address(0);
        // t2.push(address(this));
        // t2.push(address(this));
        // t2.push(address(this));

        // t2[1] = address(0);
    }
}
