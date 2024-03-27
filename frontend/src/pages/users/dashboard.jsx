import React, { useState } from "react";
import "./dashboard.css"; // Assuming you have a dashboard.css file
import { useLocation } from "react-router-dom";
import Navbar from "../../components/navbar";

const Dashboard = () => {
  const [selectedOption, setSelectedOption] = useState("Option 1");
  const [totalBorrowed, setTotalBorrowed] = useState(0);
  const [totalLent, setTotalLent] = useState(0);

  const options = ["LAND", "PROPY", "Option 3"];

  // ... other dashboard logic and data

  // const ReceiverComponent = () => {
  //   const location = useLocation();
  //   const receivedState = location.state;

  //   return <div>{receivedState}</div>;
  // };

  
const getWallet = async () => {
  if (window.ethereum) {
    setEthWallet(window.ethereum);
  }

  if (ethWallet) {
    const account = await ethWallet.request({ method: "eth_accounts" });
    handleAccount(account);
  }
};

const handleAccount = (account) => {
  if (account) {
    console.log("Account connected: ", account);
    setAccount(account);
  } else {
    console.log("No account found");
  }
};

const connectWallet = async () => {
  if (!ethWallet) {
    alert("MetaMask wallet is required to connect");
    return;
  }
  try {
    const provider = new ethers.providers.Web3Provider(window.ethereum);
    await provider.send("eth_requestAccounts");
    const accounts = await provider.listAccounts();
    setAddress(accounts[0]);
    // setIsConnected(true);
    // setWallet(accounts[0]);
    // Assuming you're using react-router-dom v6
  } catch (error) {
    console.error("Error connecting wallet:", error);
    // Handle error appropriately, e.g., display an error message to the user
  }
};

useEffect(() => {
  getWallet();
}, []);

// const getContract = () => {
//   const provider = new ethers.providers.Web3Provider(ethWallet);
//   const signer = provider.getSigner();
//   const atmContract = new ethers.Contract(contractAddress, atmABI, signer);

//   setContract(atmContract);
// };

  return (
    <div>
      <div className="dashboard">
        <Navbar />
        {/* Container for both blocks with margin from top */}
        <div className="block-container" style={{ marginTop: "20px" }}>
          <div className="block block-1">
            <h3>Total Lent</h3>
            <span>{totalLent}</span>
          </div>
          <div className="block block-2">
            <h3>Total Borrowed</h3>
            <span>{totalBorrowed}</span>
          </div>
        </div>
        <div className="token-choice">Choose your Token to Lend/Borrow</div>

        {/* Dropdown menu below the blocks */}
        <div className="dropdown-container">
          <select
            value={selectedOption}
            onChange={(e) => setSelectedOption(e.target.value)}
          >
            {options.map((option) => (
              <option key={option} value={option}>
                {option}
              </option>
            ))}
          </select>
        </div>
        <div className="input-container">
          <input type="text" placeholder="Enter amount to Borrow" />
          <input type="text" placeholder="Enter amount to Lend" />
        </div>
        <div className="button-container">
          <button className="colored-button button-1">Borrow</button>
          <button className="colored-button button-2">Lent</button>
        </div>

        <div className="content-area">{/* ... other dashboard content */}</div>
      </div>
    </div>
  );
};

export default Dashboard;
