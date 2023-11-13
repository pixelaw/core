import useLocalStorage from "../../useLocalStorage";

const RANDOM_ARRAY_LENGTH = 10
const MAX_RANDOM_NUMBER = 4294967295
const useSaltGenerator = () => {
  const [salt, setSalt] = useLocalStorage('RPS_SALT', 0)
  const changeSalt = () => {
    const randomArray: Uint32Array = (new Uint32Array(RANDOM_ARRAY_LENGTH))
      .map(() => Math.floor(Math.random() * MAX_RANDOM_NUMBER))
    for (let i = 0; i < RANDOM_ARRAY_LENGTH; i++) {
      const randomValues = crypto.getRandomValues(randomArray)
      const index = Math.floor(Math.random() * randomValues.length)
      setSalt(randomValues[index])
    }
  }

    return {
      salt,
      changeSalt
    }
  }

  export default useSaltGenerator