import * as functions from "firebase-functions/v1";
import { UserRecord } from "firebase-admin/auth";

import "./admin";
import { createUserProfileDocument } from "../services/userService";

/**
 * Auth trigger: fires when a new Firebase Auth user is created.
 * Creates the Firestore profile at users/{uid} with defaults per PRD.
 */
export const createUserProfile = functions.auth.user().onCreate(
  async (user: UserRecord) => {
    functions.logger.info("Creating user profile", { uid: user.uid, email: user.email });

    try {
      await createUserProfileDocument(user);
      functions.logger.info("User profile created", { uid: user.uid });
    } catch (error) {
      functions.logger.error("Failed to create user profile", { uid: user.uid, error });
      throw error;
    }
  },
);
