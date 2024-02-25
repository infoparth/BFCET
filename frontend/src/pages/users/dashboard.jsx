import React, { useState } from "react";
import "./dashboard.css"; // Assuming you have a dashboard.css file
import Navbar from "../../components/navbar";

const Dashboard = () => {
  const [selectedOption, setSelectedOption] = useState("Option 1");

  const options = ["Option 1", "Option 2", "Option 3"];

  // ... other dashboard logic and data

  return (
    <div>
      <div className="dashboard">
        <Navbar />
        {/* Container for both blocks with margin from top */}
        <div className="block-container" style={{ marginTop: "20px" }}>
          <div className="block block-1"></div>
          <div className="block block-2"></div>
        </div>

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

        <div className="content-area">{/* ... other dashboard content */}</div>
      </div>
    </div>
  );
};

export default Dashboard;
