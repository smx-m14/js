// Importació de mòduls necessaris de Firebase
import { initializeApp } from "https://www.gstatic.com/firebasejs/10.12.2/firebase-app.js";
import { getFirestore, doc, setDoc, getDoc, getDocs, query, collection, deleteDoc, where } from "https://www.gstatic.com/firebasejs/10.12.2/firebase-firestore.js";

// Operadors lògics permesos per a consultes a Firebase
const operators = ["==", "!=", "<", ">", ">=", "<="];

// Variable global per emmagatzemar la base de dades
var database;

/**
 * Prepara la base de dades Firestore segons la configuració indicada.
 * @param {object} config - Configuració del projecte Firebase.
 */
function prepareDatabase(config) {
  var app = initializeApp(config);
  database = getFirestore(app);
}

/**
 * Obté un document de la col·lecció especificada.
 * @param {string} collection - Nom de la col·lecció.
 * @param {string} id - Identificador del document.
 * @returns {object|null} - El contingut del document o null si no existeix.
 */
async function getDocument(collection, id) {
  const docRef = doc(database, collection, String(id));
  const docSnap = await getDoc(docRef);
  return docSnap.exists() ? docSnap.data() : null;
}

/**
 * Obté tots els documents d'una col·lecció.
 * @param {string} col - Nom de la col·lecció.
 * @returns {Array} - Llista de documents.
 */
async function getCollection(col) {
  const q = query(collection(database, col));
  const querySnap = await getDocs(q);
  return querySnap.empty ? [] : querySnap.docs.map(doc => doc.data());
}

/**
 * Obté documents d'una col·lecció segons una condició.
 * @param {string} col - Nom de la col·lecció.
 * @param {string} condition - Condició en format "camp operador valor".
 * @returns {Array} - Llista de documents que compleixen la condició.
 */
async function getDocumentsWhere(col, condition) {
  const [field, operator, ...rest] = condition.split(" ");
  if (!operators.includes(operator)) {
    console.log("Operador lògic no vàlid");
    return [];
  }
  const value = rest.join(" ").replace(/^'+|'+$/g, '');
  const q = query(collection(database, col), where(field, operator, value));
  const querySnap = await getDocs(q);
  return querySnap.empty ? [] : querySnap.docs.map(doc => doc.data());
}

/**
 * Buida tots els documents d'una col·lecció.
 * @param {string} col - Nom de la col·lecció.
 */
async function emptyCollection(col) {
  const querySnap = await getDocs(query(collection(database, col)));
  querySnap.forEach(doc => deleteDocument(col, doc.id));
}

/**
 * Desa un document a la col·lecció especificada.
 * @param {string} collection - Nom de la col·lecció.
 * @param {string} id - Identificador del document.
 * @param {object} data - Dades del document.
 */
async function saveDocument(collection, id, data) {
  try {
    await setDoc(doc(database, collection, String(id)), data, { merge: true });
  } catch (error) {
    console.log("Error en desar el document: ", error);
  }
}

/**
 * Elimina un document d'una col·lecció.
 * @param {string} collection - Nom de la col·lecció.
 * @param {string} id - Identificador del document.
 */
async function deleteDocument(collection, id) {
  try {
    await deleteDoc(doc(database, collection, String(id)));
  } catch (error) {
    console.log("Error en eliminar el document: ", error);
  }
}

// Exportació de les funcions per al seu ús extern
export { prepareDatabase, getDocument, saveDocument, getCollection, deleteDocument, emptyCollection, getDocumentsWhere };
