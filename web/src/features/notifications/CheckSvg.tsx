import React from "react";

export const CheckSvg: React.FC = () => (
  <svg
    width="32"
    height="32"
    viewBox="0 0 40 42"
    preserveAspectRatio="xMidYMid meet"
    fill="none"
    xmlns="http://www.w3.org/2000/svg"
  >
    <g filter="url(#filter3_d_26_42)">
      <path
        d="M12 22l6 6 10-14"
        stroke="#00F8B9"
        strokeWidth="4"
        strokeLinecap="round"
        strokeLinejoin="round"
        fill="none"
      />
    </g>
    <defs>
      <filter
        id="filter3_d_26_42"
        x="6"
        y="0"
        width="28"
        height="42"
        filterUnits="userSpaceOnUse"
        colorInterpolationFilters="sRGB"
      >
        <feFlood floodOpacity="0" result="BackgroundImageFix" />
        <feColorMatrix
          in="SourceAlpha"
          type="matrix"
          values="0 0 0 0 0  0 0 0 0 0  0 0 0 0 127  0"
          result="hardAlpha"
        />
        <feOffset dy="4" />
        <feGaussianBlur stdDeviation="4.5" />
        <feComposite in2="hardAlpha" operator="out" />
        <feColorMatrix
          type="matrix"
          values="0 0 0 0 0.972549  0 0 0 0 0.72549  0 0 0 1 0"
        />
        <feBlend
          mode="normal"
          in2="BackgroundImageFix"
          result="effect1_dropShadow_26_42"
        />
        <feBlend
          mode="normal"
          in="SourceGraphic"
          in2="effect1_dropShadow_26_42"
          result="shape"
        />
      </filter>
    </defs>
  </svg>
);

export default CheckSvg;
