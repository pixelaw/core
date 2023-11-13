import React, { useState, useEffect } from "react";

const useLocalStorage: <T>(key: string, defaultValue: T) => [T,  React.Dispatch<React.SetStateAction<T>>] = <T>(key: string, defaultValue: T) => {
  const [value, setValue] = useState<T>(() => {
    const currentStringValue = localStorage.getItem(key)
    if (!currentStringValue) return defaultValue
    let currentValue: T;

    if (typeof defaultValue === "string") return currentStringValue as T

    try {
      currentValue = JSON.parse(currentStringValue);
    } catch (error) {
      currentValue = defaultValue;
    }
    return currentValue;
  });

  useEffect(() => {
    if (value === '') localStorage.removeItem(key)
    else if (typeof defaultValue === "string") localStorage.setItem(key, value as string);
    else localStorage.setItem(key, JSON.stringify(value));
  }, [value, key]);

  return [value, setValue];
};

export default useLocalStorage;
