// WalletContext.js
import React, { useState, useEffect } from "react";
import { ethers } from "ethers";

const WalletProvider = ({ children }) => {
  const [walletAddress, setWalletAddress] = useState(null);

  const connectWallet = async () => {
    if (window.ethereum) {
      alert("MetaMask wallet is required to connect");
      return;
    }
    try {
      const provider = new ethers.providers.Web3Provider(window.ethereum);
      await provider.send("eth_requestAccounts");
      const accounts = await provider.listAccounts();
      setWalletAddress(accounts[0]);
      //   setAddress(accounts[0]);
      // setIsConnected(true);
      // setWallet(accounts[0]);
      // Assuming you're using react-router-dom v6
      //   navigate("/dashboard");
    } catch (error) {
      console.error("Error connecting wallet:", error);
      // Handle error appropriately, e.g., display an error message to the user
    }
  };

  // Connect to your chosen wallet provider and store address in context
  // Replace with your specific provider library's connection logic
  useEffect(() => {
    // ... wallet connection logic
    connectWallet();
  }, []);

  return (
    <WalletContext.Provider value={{ walletAddress, setWalletAddress }}>
      {children}
    </WalletContext.Provider>
  );
};

export default WalletProvider;
