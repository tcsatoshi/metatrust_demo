import "@stdlib/deploy";
import "@stdlib/ownable";
message Deposit {
    holder: Address;
    amount: Int as uint64;
}
message Unstake {
    holder: Address;
    amount: Int as uint64;
    to: Address;
}

contract MpTrust with Deployable, Ownable {
    owner: Address;
    depList: map<Address, Int as uint256>;
    unstakeSwitch: Bool;
    startTime: Int as uint32;
    init(){
        self.owner = sender();
        self.depList = emptyMap();
        self.unstakeSwitch = false;
        self.startTime = now();
    }

    receive(){
        self.requireOwner();
    }

    receive("Toogle Switch"){
        self.requireOwner();
        self.unstakeSwitch = !(self.unstakeSwitch);
    }

    receive("Clear"){
        self.requireOwner();
        send(SendParameters{to: self.owner, bounce: true, value: 0, mode: (SendRemainingBalance + SendIgnoreErrors)});
    }

    receive(uns: Unstake){
        require(self.unstakeSwitch, "not now");
        require(uns.holder == sender(), "wrong sender");
        require(uns.to != null, "wrong receiver");
        require(self.depList.get(uns.holder) != null, "no record");
        let blc: Int = self.depList.get(uns.holder)!!;
        self.depList.set(uns.holder, null);
        send(SendParameters{to: uns.to, bounce: true, value: blc, mode: SendIgnoreErrors});
    }

    receive(dep: Deposit){
        let sendValue: Int = context().value;
        require(dep.amount > 0 && sendValue >= dep.amount, "wrong value");
        require(dep.holder == sender(), "wrong sender");
        let blc: Int = 0;
        if (self.depList.get(dep.holder) == null) {
            blc = sendValue;
        } else {
            blc = (self.depList.get(dep.holder)!! + sendValue);
        }
        self.depList.set(dep.holder, blc);
    }

    get fun staked(u: Address): Int {
        if (self.depList.get(u) == null) {
            return 0;
        } else {
            return self.depList.get(u)!!;
        }
    }

    get fun balance(): Int {
        return myBalance();
    }

    get fun switch(): Bool {
        return self.unstakeSwitch;
    }
}