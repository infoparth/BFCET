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

  function onClicks() {
    navigate("/dashboard");
  }

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
          <button className="dashboard-button" onClick={onClicks}>
            Get In
          </button>
        )}
      </div>
    </div>
  );
};

export default LandingPage;









