import React, { useState, useEffect } from "react";
import "./landingpage.css";
import { Link } from "react-router-dom";
// import { ConnectWallet, useAddress } from "@thirdweb-dev/react";
import { ethers } from "ethers";
import { useNavigate } from "react-router-dom";

const LandingPage = () => {
  const [isConnected, setIsConnected] = useState(false);
  const [address, setAddress] = useState(null);
  const [ethWallet, setEthWallet] = useState();
  const [account, setAccount] = useState();

  const navigate = useNavigate();

  //   const address = useAddress();

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
      setIsConnected(true);
      // Assuming you're using react-router-dom v6
      navigate("/dashboard");
    } catch (error) {
      console.error("Error connecting wallet:", error);
      // Handle error appropriately, e.g., display an error message to the user
    }
  };

  useEffect(() => {
    getWallet();
  }, []);

  return (
    <div className="landing-page">
      <img
        src="path/to/your/background-image.jpg"
        alt="Product Background"
        className="landing-page-bg"
      />
      <div className="landing-page-content">
        <h1 className="product-name">Real-Chain</h1>
        {isConnected ? (
          <Link className="dashboard-button" to="/dashboard">
            Go to Dashboard
          </Link>
        ) : (
          <button className="dashboard-button" onClick={connectWallet}>
            Connect Wallet
          </button>
        )}
      </div>
    </div>
  );
};

export default LandingPage;
