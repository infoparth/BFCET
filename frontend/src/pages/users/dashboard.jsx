import React, { useState } from "react";
import "./dashboard.css"; // Assuming you have a dashboard.css file
import Navbar from "../../components/navbar";

const Dashboard = () => {
  const [selectedOption, setSelectedOption] = useState("Option 1");
  const [totalBorrowed, setTotalBorrowed] = useState(0);
  const [totalLent, setTotalLent] = useState(0);

  const options = ["LAND", "PROPY"];

  // const getContract = () => {
  //   const provider = new ethers.providers.Web3Provider(ethWallet);
  //   const signer = provider.getSigner();
  //   const atmContract = new ethers.Contract(contractAddress, atmABI, signer);

  //   setContract(atmContract);
  // };

  // ... other dashboard logic and data

  return (
    <div>
      <div className="dashboard">
        <Navbar />
        {/* Container for both blocks with margin from top */}
        <div className="block-container" style={{ marginTop: "20px" }}>
          <div className="block block-1">
            <h3>Total Tokens Lent</h3>

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

        <div className="button-container">
          <button className="colored-button button-1">Lend Asset</button>
          <button className="colored-button button-2">Deposit Asset</button>
        </div>

        <div className="content-area">{/* ... other dashboard content */}</div>
      </div>
    </div>
  );
};

export default Dashboard;
